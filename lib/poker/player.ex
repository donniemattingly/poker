defmodule Poker.Player do
  @moduledoc """
  This module is a GenServer implementation meant to interact with a Poker.Table instance

  It can view available tables via the registry, attempt to join those tables, and play hands.

  Once a player joins a table, the table will coordinate informing the player when the action is on
  them, and will periodically update the player on game state.

  There are essentially two clients that will use this module, the Table when communicating about pending
  action and game state, and the players themselves (typically through a phoenix channel) sending actions
  to be performed in the game.

  Game state is the following
    - Player Info
      - name
      - stack size
      - position
      - last action (check, call, fold, bet, raise, or all-in)
    - Pot
      - size
      - sidepots if any
    - Community Cards
    - Action
    - Button
  """

  use GenServer

  @impl true
  def init(_opts) do

  end

  """
  #### Client ####

  """

  def join_table(player, table) do
    GenServer.call(player, {:join_table, table})
  end

  def leave_table(player) do
    GenServer.call(player, :leave_table)
  end

  @doc """
    Call here being the poker action not the GenServer function
  """
  def call(player) do
    GenServer.call(player, :call)
  end

  def check(player) do
    GenServer.call(player, :check)
  end

  def fold(player) do
    GenServer.call(player, :fold)
  end

  def bet(player, amount) do
    GenServer.call(player, {:bet, amount})
  end

  def raise(player, amount) do
    GenServer.call(player, {:raise, amount})
  end

  def update_time_remaining(player, time_remaining) do
    GenServer.call(player, {:time_remaining, time_remaining})
  end

  def update_game(player, game) do
    GenServer.call(player, {:update_game, game})
  end

  #### Server ####

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:join_table, table}, _from, state) do
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast(_msg, state) do
    {:noreply, state}
  end
end