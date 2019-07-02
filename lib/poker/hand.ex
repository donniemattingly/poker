defmodule Poker.Hand do
  @moduledoc false

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

  def convert_shorthand(hand) when is_list(hand) do
    Enum.map(hand, &convert_shorthand(&1))
  end

  def convert_shorthand(hand) do
    [rank | [suit | _]] =
      String.graphemes(hand)
      |> Enum.map(&Map.get(@shorthand_mappings, &1, &1))

    case is_atom(rank) do
      true -> {rank, suit}
      _ -> case Integer.parse(rank) do
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

  def is_flush do

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