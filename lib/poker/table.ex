defmodule Poker.Table do
  use GenServer

  def start_link(state, opts) do
    GenServer.start_link(__MODULE__, state, opts)
  end

  def init(_opts) do
    players = [
      %{name: "p1", chips: 100, table_position: 0},
      %{name: "p2", chips: 100, table_position: 1}
    ]
    community_cards = []
    button = 0
    deck = Poker.Deck.shuffle()

    {:ok, {players, community_cards, button, deck}}
  end

  def handle_call({:player_joined}, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call({:player_left}, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call({:player_joined}, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call({:player_joined}, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end
end

defmodule Player do
  defstruct [:name, :stack, :cards,]
end