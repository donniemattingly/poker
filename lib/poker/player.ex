defmodule Poker.Player do
  @moduledoc """
  This module is a GenServer implementation meant to interact with a Poker.Table instance

  It can view available tables via the registry, attempt to join those tables, and play hands.

  Once a player joins a table, the table will coordinate informing the player when the action is on
  them, and will periodically update the player on game state.

  There are essentially two clients that will use this module, the Table when communicating about pending
  action and game state, and the players themselves (typically through a phoenix channel) sending actions
  to be performed in the game.
  """

  use GenServer

  def start_link(state, opts) do
    GenServer.start_link(__MODULE__, state, opts)
  end

  #### Client ####


  #### Server ####

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast(_msg, state) do
    {:noreply, state}
  end
end