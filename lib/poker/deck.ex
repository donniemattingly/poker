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

  @doc """
  Takes a list of cards `deck`, a list of `players`, and a number (`num_cards`)

  Deals every player `num_cards` cards from the top of `deck`
  Returns new players (with `:hand` having the cards) and the remaining deck
  """
  def deal(deck, players, num_cards) do
    {to_deal, remaining} = deck |> Enum.split(length(players) * num_cards)
    hands = Enum.chunk_every(to_deal, num_cards)

    players_with_hands =
      Enum.zip(players, hands)
      |> Enum.map(fn {player, hand} -> Map.put(player, :hand, hand) end)

    {players_with_hands, remaining}
  end
end
