defmodule Poker.Table do
  use GenServer

  alias Poker.Hand
  alias Poker.Deck

  def start_link(state, opts) do
    GenServer.start_link(__MODULE__, state, opts)
  end

  def init(_opts) do
    players = [
      %{name: "p1", chips: 100, table_position: 0},
      %{name: "p2", chips: 100, table_position: 1},
      %{name: "p3", chips: 100, table_position: 2},
      %{name: "p4", chips: 100, table_position: 3},
      %{name: "p5", chips: 100, table_position: 4},
      %{name: "p6", chips: 100, table_position: 5}
    ]

    community_cards = []
    button = 0
    deck = Poker.Deck.shuffle()

    {:ok, {players, community_cards, button, deck}}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end



  @doc """
  Given a list of players deals them 2 hole cards each and returns a tuple
  with the players and the community cards
  """
  def deal_hand(players) do
    deck = Deck.shuffle()
    community_cards = Enum.take(deck, 5)

    new_players = deck
    |> Enum.chunk_every(2)
    |> Enum.take(length(players))
    |> Enum.zip(players)
    |> Enum.map(fn({cards, player}) -> Map.put(player, :hole_cards, cards) end)

    {community_cards, new_players}
  end


  @doc """
  Given a list of players and the community cards returns
  a sorted list of players with their score added
  """
  def showdown(players_remaining, community_cards) do
    players_remaining
    |> Enum.map(fn player ->
      Map.put(player, :hand, player.hole_cards ++ community_cards)
    end)
    |> Enum.map(fn player ->
      Map.put(player, :hand_score, Poker.Hand.score_hand(player.hand))
    end)
    |> Enum.sort(fn p1, p2 ->
      Poker.Hand.compare_hand_score(p1.hand_score, p2.hand_score)
    end)
  end
end
