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
  Takes an array of 7 cards, the `hand` and returns a score struct
  """
  def score_hand do
  end


  @doc """
  Converts rank (which is either an atom or an int) to an int (ace high)
  """
  defp normalize_rank(r) do
    case r do
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
  defp compare_rank(r1, r2) do
    n1 = normalize_rank(r1)
    n2 = normalize_rank(r2)
    n2 <= n1
  end

  @doc """
  Handles pair, two-pair, set, full-house, and quads
  """
  def score_by_rank(hand) do
    Enum.group_by(hand, &Kernel.elem(&1, 0))
    |> score_groups_by_rank
  end

  @doc """
  Handles flushes
  """
  def score_by_suit(hand) do
    groups = Enum.group_by(hand, &Kernel.elem(&1, 1))
  end

  @doc """
  Handles straight
  """
  def score_straight(hand) do
    groups = Enum.group_by(hand, &Kernel.elem(&1, 0))
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
    l1 = elem(g1, 1)
         |> length
    l2 = elem(g2, 1)
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
    {
      @hand_primary_values.quads,
      elem(quads, 0)
      |> normalize_rank,
      kickers
      |> Enum.flat_map(&Kernel.elem(&1, 1))
      |> score_kickers
    }
  end

  def score_full_house(groups) do
    {
    @hand_primary_values.full_house,

    }
  end

  def score_trips(groups) do

  end

  def score_two_pair(groups) do

  end

  def score_pair(groups) do

  end

  def score_high_card(groups) do

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
    |> Enum.zip(length(cards)-1..0)
    |> Enum.map(fn ({rank, n}) ->
      rank <<< 4 * n
    end)
    |> Enum.sum
  end

  @doc """
  For n kickers rank cards lowest to highest, then multiply by 0..n powers of 10
  TODO: this will break sometimes
  """
  def score_kickers(cards)do
    magnitude = length(cards)
    cards
    |> Enum.sort(&compare_rank(&2, &1))
    |> Enum.map(&Kernel.elem(&1, 0))
    |> Enum.map(&normalize_rank(&1))
    |> Enum.zip(0..magnitude)
    |> Enum.map(fn {rank, mag} -> rank * :math.pow(mag, 10) end)
    |> Enum.map(&Kernel.round(&1))
    |> Enum.sum
  end
end

defmodule Poker.Hand.Score do
  @moduledoc """
  Score is a struct containing a field for each possible hand w/ min defining characteristics

  straight_flush - high card
  quads - rank (kicker never matters)
  full_house - rank1 full of rank2
  flush - all cards needed
  straight - high card
  set - set_rank, kickers
  two_pair rank1, rank2, kickers
  pair rank, kickers
  high_card kickers
  """
end
