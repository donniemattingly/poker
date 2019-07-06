defmodule Poker.Simulate do
  use Task

  alias Poker.Hand
  alias Poker.Deck


  def get_relative_occurrence_of_hands(sample_size) do
    Task.async_stream(
      0..sample_size,
      fn _ ->
        Poker.Deck.deal_hand(7)
        |> Poker.Hand.score_hand end
    )
    |> Enum.map(&elem(&1, 1))
    |> Enum.group_by(&elem(&1, 0))
    |> Map.to_list
    |> Enum.map(fn ({rank, hands}) -> {rank, length(hands) / sample_size} end)
  end


  def get_random_hands_of_type(type, amount) do
    Stream.cycle(0..1)
    |> Stream.map(fn _ ->
      Poker.Deck.deal_hand(7)
      |> Poker.Hand.score_hand end)
    |> Stream.filter(fn ({r, _, _, _}) -> r == type end)
    |> Enum.take(amount)
  end

end
