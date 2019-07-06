defmodule Poker.Hand do
  use Bitwise

  @moduledoc """
  Hands score is a tuple with the following elements
    - integer representing the hand score (0-8)
    - integer representing the relative hand score
    - integer representing the kicker score
    - description of the hand (pair of aces, king high, threes full of aces, etc)

    the last two scores are only comparable within a specific hand
  """

  @shorthand_mappings %{
    "A" => :a,
    "K" => :k,
    "Q" => :q,
    "J" => :j,
    "H" => :hearts,
    "S" => :spades,
    "D" => :diamonds,
    "C" => :clubs,
    "T" => "10"
  }

  @hand_primary_values %{
    high_card: 0,
    pair: 1,
    two_pair: 2,
    set: 3,
    straight: 4,
    flush: 5,
    full_house: 6,
    quads: 7,
    straight_flush: 8
  }

  def from_shorthand(hand) when is_list(hand) do
    Enum.map(hand, &from_shorthand(&1))
  end

  def to_shorthand(hand) do
    inverted =
      @shorthand_mappings
      |> Map.to_list()
      |> Map.new(fn {k, v} -> {v, k} end)

    hand
    |> Enum.map(
         fn {rank, suit} ->
           rankStr =
             case Map.get(inverted, rank) do
               nil -> rank
               x -> x
             end

           suitStr =
             case suit do
               :diamonds -> "D"
               :hearts -> "H"
               :spades -> "S"
               :clubs -> "C"
             end

           "#{rankStr}#{suitStr}"
         end
       )
    |> Enum.join(" ")
  end

  def from_shorthand(hand) do
    [rank | [suit | _]] =
      String.graphemes(hand)
      |> Enum.map(&Map.get(@shorthand_mappings, &1, &1))

    case is_atom(rank) do
      true ->
        {rank, suit}

      _ ->
        case Integer.parse(rank) do
          {value, _} -> {value, suit}
          _ -> {rank, suit}
        end
    end
  end

  @doc """
  sorts hands by score
  """
  def compare_hand_score({p0, h0, k0, c0}, {p1, h1, k1, c1}) do
    {p0, h0, k0} > {p1, h1, k1}
  end

  @doc """
  Takes an array of 7 cards, the `hand` and returns a score struct
  """
  def score_hand(hand) do
    [score_by_rank(hand), score_by_suit(hand), score_straight(hand)]
    |> Enum.sort(&compare_hand_score(&1, &2))
    |> Enum.at(0)
  end

  @doc """
  Converts rank (which is either an atom or an int) to an int (ace high)
  """
  def normalize_rank(r) do
    case r do
      :al -> 1
      :j -> 11
      :q -> 12
      :k -> 13
      :a -> 14
      _ -> r
    end
  end

  @doc """
  Comparator for sorting cards by rank (ace high)
  """
  def compare_rank(r1, r2) do
    n1 = normalize_rank(r1)
    n2 = normalize_rank(r2)
    n2 <= n1
  end

  @doc """
  Handles pair, two-pair, set, full-house, and quads
  """
  def score_by_rank(hand) do
    Enum.group_by(hand, &Kernel.elem(&1, 0))
    |> Map.to_list()
    |> Enum.sort(&sort_groups(&1, &2))
    |> score_groups_by_rank
  end

  @doc """
  Handles flushes
  """
  def score_by_suit(hand) do
    {selected_hand, suited_group} =
      Enum.group_by(hand, &Kernel.elem(&1, 1))
      |> Enum.group_by(&Kernel.elem(&1, 1))
      |> Enum.sort(&Poker.Hand.sort_groups(&1, &2))
      |> Enum.at(0)

    result = case length(selected_hand) do
      5 -> {
             @hand_primary_values.flush,
             cards_to_comparable_int(selected_hand),
             0,
             selected_hand
           }
      _ -> {0, 0, 0, 0}
    end

    result
  end

  @doc """
  Handles straight & straight flush

  as a hack we add one card of ":al" or ace-low
  to the hand per ace
  """
  def score_straight(hand) do
    ace_lows =
      hand
      |> Enum.filter(fn ({rank, suit}) -> rank == :a end)
      |> Enum.map(fn ({:a, suit}) -> {:al, suit} end)

    straights =
      hand ++ ace_lows
      |> Enum.sort(fn {r1, _}, {r2, _} -> Poker.Hand.compare_rank(r1, r2) end)
      |> Enum.dedup_by(&elem(&1, 0))
      |> Enum.chunk_every(5, 1)
      |> Enum.filter(fn l -> length(l) == 5 end)
      |> Enum.filter(
           fn l ->
             first = Enum.at(l, 0)
                     |> elem(0)
                     |> normalize_rank
             last = Enum.at(l, 4)
                    |> elem(0)
                    |> normalize_rank
             first - last == 4
           end
         )

    straight_flush =
      straights
      |> Enum.filter(
           fn h ->
             1 == Enum.dedup_by(h, &elem(&1, 1))
                  |> length
           end
         )
      |> Enum.at(0)

    best_straight = Enum.at(straights, 0)

    {primary_score, selected_hand} =
      case straight_flush do
        nil -> {@hand_primary_values.straight, best_straight}
        sf -> {@hand_primary_values.straight_flush, sf}
      end

    case selected_hand do
      nil ->
        {0, 0, 0, 0}

      s ->
        {
          primary_score,
          s
          |> Enum.at(0)
          |> elem(0)
          |> normalize_rank,
          0,
          convert_ace_lows(s)
        }
    end
  end

  def convert_ace_lows(hand) do
    hand
    |> Enum.map(
         fn ({rank, suit}) -> case rank do
                                :al -> {:a, suit}
                                _ -> {rank, suit}
                              end
         end
       )
  end

  defp group_size(group) do
    elem(group, 1)
    |> length
  end

  @doc """
    groups are a tuple of {rank, [cards]} representing grouped ranks (e.g. pairs, sets)
    this sorts groups in poker order (more in group best, ties broken by rank)
  """
  def sort_groups(g1, g2) do
    case group_size(g1) - group_size(g2) do
      x when x > 0 -> true
      x when x < 0 -> false
      0 -> compare_rank(elem(g1, 0), elem(g2, 0))
    end
  end

  @doc """
  takes a sorted list of groups and returns a score if
  that group has quads, false otherwise
  """
  def score_groups_by_rank(groups) do
    [g1 | [g2 | _]] = groups

    l1 =
      elem(g1, 1)
      |> length

    l2 =
      elem(g2, 1)
      |> length

    case {l1, l2} do
      {4, _} -> score_quads(groups)
      {3, 2} -> score_full_house(groups)
      {3, _} -> score_trips(groups)
      {2, 2} -> score_two_pair(groups)
      {2, _} -> score_pair(groups)
      _ -> score_high_card(groups)
    end
  end

  def score_quads([quads | kickers]) do
    selected_kickers =
      kickers
      |> Enum.take(1)

    {
      @hand_primary_values.quads,
      elem(quads, 0)
      |> normalize_rank,
      selected_kickers
      |> cards_to_comparable_int,
      ([quads] ++ selected_kickers)
      |> Enum.flat_map(&elem(&1, 1))
    }
  end

  @doc """
    only differentiation between full houses is the
    type of trip and pair, so no value for kicker score
  """
  def score_full_house([trips | [pair | kickers]]) do
    {
      @hand_primary_values.full_house,
      [trips, pair]
      |> cards_to_comparable_int,
      0,
      [trips,pair]
      |> Enum.flat_map(&elem(&1, 1))
    }
  end

  @doc """
    use rank of trips for comparision
    use two best kickers
  """
  def score_trips([trips | kickers]) do
    selected_kickers =
      kickers
      |> Enum.take(2)

    {
      @hand_primary_values.set,
      elem(trips, 0)
      |> normalize_rank,
      selected_kickers
      |> cards_to_comparable_int,
      ([trips] ++ selected_kickers)
      |> Enum.flat_map(&elem(&1, 1))
    }
  end

  @doc """
    rank of each pair matters
    use one kicker
  """
  def score_two_pair([p1 | [p2 | kickers]]) do
    selected_kickers =
      kickers
      |> Enum.take(1)

    {
      @hand_primary_values.two_pair,
      [p1, p2]
      |> cards_to_comparable_int,
      selected_kickers
      |> cards_to_comparable_int,
      ([p1, p2] ++ selected_kickers)
      |> Enum.flat_map(&elem(&1, 1))
    }
  end

  @doc """
  three kickers, rank of pair matters
  """
  def score_pair([pair | kickers]) do
    selected_kickers =
      kickers
      |> Enum.take(3)

    {
      @hand_primary_values.pair,
      elem(pair, 0)
      |> normalize_rank,
      selected_kickers
      |> cards_to_comparable_int,
      ([pair] ++ selected_kickers)
      |> Enum.flat_map(&elem(&1, 1))
    }
  end

  @doc """
    All kickers
  """
  def score_high_card(groups) do
    selected_kickers =
      groups
      |> Enum.take(5)

    {
      @hand_primary_values.high_card,
      0,
      selected_kickers
      |> cards_to_comparable_int,
      selected_kickers
    }
  end

  @doc """
  Given a list of unique cards returns an integer

  given a collection of card lists this can be used to sort in
  poker order.

  Takes the list [Ah, Td, 7c] and converts it to 0xEA7
  """
  def cards_to_comparable_int(cards) do
    cards
    |> Enum.map(&elem(&1, 0))
    |> Enum.map(&normalize_rank(&1))
    |> Enum.zip((length(cards) - 1)..0)
    |> Enum.map(
         fn {rank, n} ->
           rank
           <<< (4 * n)
         end
       )
    |> Enum.sum()
  end
end

