defmodule Poker.Table do
  @moduledoc """
  The Table module handles coordinating multiple player processes in a game
  it deals cards, receives bets, assigns blinds, determines winners, and pays
  out the pot when a hand completes

  `config` is a struct containing various config info (blind size, table size, etc)
  `players` are stored in a map of name => player
  `position`s are stored in a separate map of pos => player_name
  `button` is a position, specifically a key of the position map that moves after each hand
  `deck` is the deck for the current hand, resets after each hand
  `community_cards` is an array of 0 to 5 community cards
  `action` is a position indicating which player has the current action

  A table process will wait until it has the minimum number of players before starting a hand

  The lifecycle of a hand is roughly made of three parts, with the second repeating each betting round

  ### Setup

  - move the button clockwise
  - assign blinds based on button position
  - generate a new shuffled deck
  - action is assigned to the UTG player

  ### Betting rounds

  Betting rounds consist of one or more subrounds, where each subround is started either by the big blind, the first
  player to act, or any act that raises the current round's bet. A subround is really just a position at the table where
  the betting round ends when the player directly counter-clockwise of the subround starting player finishes their
  action.

  - player with action selects an action (depending on game state)
    - if there are no bets (either all checks or player is first to act)
      - bet (with rules based on betting round and blind size) (new subround starts)
      - check
      - fold
    - if there are bets
      - raise (with rules around min raises) (new subround starts)
      - call
      - fold
  - once the player with action completes his turn, action moves clockwise
  - each player is presented with the same options as above
  - once the current player acts if the current player position is subround_start_pos - 1 the betting round ends
  - if the betting round finishes and only one player remains, the hand is over
  - if there are no more cards to be dealt (i.e. the betting round that finished was :river) the hand is over
  - otherwise the hand advances in state (:pre_flop -> :flop -> :turn -> :river) and another betting round begins
  - when the hand advances in state some additional number (either 3 or 1) of cards are added to `community_cards`

  ### Finishing a hand

  - if there is only one player remaining the entirety of the `pot` is award to that player and a new hand begins
  - if more than one player is left at this stage, players go into a showdown
  - showdowns
    - all player hands are scored via `Poker.hand.score_hand`
    - players go clockwise from the player with action either showing or mucking their hand
      - a muck removes that player's hand from scoring
      - by default, a player will muck their hand if it is not a higher score than any hand already showing
    - the player(s) with the best showing hand win the pot
      - in the event of multiple players having the best hand score, the pot is chopped (with leftover chips
        rolling over to the next hand)
  - a new hand begins


  ## Implementation

  a `table` process will communicate with some number of `player` processes, where the table notifies the players
  of game state (including pending action on the players part), and the player notifies the table of their (its really)
  action. All actions are driven from player action with the exception of new hands being triggered when one finishes.
  Additionally, every action request (game state update) sent to the player is accompanied by a `send_after` call from
  the table process to itself acting as a time limit on player action. If the player does not act before their time
  expires the default action given the game state will be taken on the players behalf. (Default action is check if valid
  or a fold otherwise).
  """
  use GenStateMachine

  alias Poker.Hand
  alias Poker.Deck

  def handle_event(:cast, :flip, :off, data) do
    {:next_state, :on, data + 1}
  end

  def handle_event(:cast, :flip, :on, data) do
    {:next_state, :off, data}
  end

  def handle_event({:call, from}, :get_count, state, data) do
    {:next_state, state, data, [{:reply, from, data}]}
  end

  def handle_event(_event_type, _event, state, data) do
    IO.puts("Event")
    {:next_state, state, data}
  end


  @doc """
  state is either
    - :waiting_for_players
    - :hand_setup
    - :pre_flop
    - :flop
    - :turn
    - :river
    - :showdown
    - :hand_complete
  """
  def init(opts) do
    players = [
      %{name: "p1", chips: 100, table_position: 0},
      %{name: "p2", chips: 100, table_position: 1},
      %{name: "p3", chips: 100, table_position: 2},
      %{name: "p4", chips: 100, table_position: 3},
      %{name: "p5", chips: 100, table_position: 4},
      %{name: "p6", chips: 100, table_position: 5}
    ]
    |> Enum.map(fn(player) -> {player.name, player} end)
    |> Map.new


    community_cards = []
    button = 0
    deck = Poker.Deck.shuffle()

    {:ok, {players, community_cards, button, deck}}

    {:ok, :off, 0}
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
