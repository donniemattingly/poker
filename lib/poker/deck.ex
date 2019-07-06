defmodule Poker.Deck do
  @moduledoc false

  def new do
    for suit <- [:hearts, :clubs, :diamonds, :spades],
        face <- [2, 3, 4, 5, 6, 7, 8, 9, 10, :j, :q, :k, :a],
        do: {face, suit}
  end

  def shuffle(deck \\ new) do
    Enum.shuffle(deck)
  end

  def deal(size) do
    shuffle
    |> Enum.take(size)
  end
end
