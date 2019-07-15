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

  def get_state(table) do
    result = :sys.get_status(table)
    {_, _, {_, _}, [_, _, _, _, [_, _, data: data]]} = result
    [{_, {state, _}}] = data
    state
  end

  def join_table(table, player) do
    GenStateMachine.call(table, {:player_join, player})
  end

  def start_table(config \\ nil) do
    GenStateMachine.start_link(Poker.Table, config)
  end

  def table_info(table) do
    GenStateMachine.call(table, :get_info)
  end

  def handle_event({:call, from}, {:player_join, player}, :waiting_for_players, data) do
    {players, cards, positions_of_interest, config} = data
    {all_players, in_hand} = players

    max_players = config.table_size
    num_players = all_players
                  |> Map.to_list
                  |> length


    new_players = add_player_to_table(player, players, config.table_size)
    next_state = case num_players do
      0 -> :waiting_for_players
      1 -> :hand_setup
    end

    new_data = {new_players, cards, positions_of_interest, config}
    actions = [{:reply, from, {:joined_table, sanitize_table_state(new_data)}}]

    {:next_state, next_state, new_data, actions}
  end


  @doc """
  When you add a player to the table you must:
    - add them to the map of players
    - set their status to be :waiting_on_big_blind
    - if the player has no seat selected, one will be randomly assigned
  """
  def add_player_to_table(player, {players, in_hand}, table_size) do
    player_with_status = Map.put(player, :status, :waiting_for_big_blind)
    position = case Map.get(player, :position) do
      nil -> randomly_assign_position(player, players, table_size)
      x -> x
    end

    player_with_position = Map.put(player_with_status, :position, position)
    new_players = Map.put(players, player_with_position.name, player_with_position)

    {new_players, in_hand}
  end


  @doc"""
  position is 0 indexed
  """
  def randomly_assign_position(player, players, table_size) do
    possible = 0..table_size - 1 |> MapSet.new
    taken = players |> Enum.map(fn ({name, player}) -> player.position end) |> MapSet.new
    remaining = MapSet.difference(possible, taken)
    Enum.random(remaining)
  end

  def handle_event(:cast, :flip, :off, data) do
    {:next_state, :on, data + 1}
  end

  def handle_event(:cast, :flip, :on, data) do
    {:next_state, :off, data}
  end

  def handle_event({:call, from}, :get_info, state, data) do
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

    config = case opts do
      nil -> %{table_size: 6}
      x -> x
    end

    community = []
    muck = []
    deck = Poker.Deck.shuffle()
    cards = {community, muck, deck}

    button = nil
    small_blind = nil
    big_blind = nil
    action = nil
    positions_of_interest = {button, small_blind, big_blind, action}

    all_players = %{}
    in_hand = []
    players = {all_players, in_hand}

    data = {players, cards, positions_of_interest, config}

    {:ok, :waiting_for_players, data}

    #    {:ok, :off, 0}
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
                  |> Enum.map(fn ({cards, player}) -> Map.put(player, :hole_cards, cards) end)

    {community_cards, new_players}
  end


  @doc """
  Given a list of players and the community cards returns
  a sorted list of players with their score added
  """
  def showdown(players_remaining, community_cards) do
    players_remaining
    |> Enum.map(
         fn player ->
           Map.put(player, :hand, player.hole_cards ++ community_cards)
         end
       )
    |> Enum.map(
         fn player ->
           Map.put(player, :hand_score, Poker.Hand.score_hand(player.hand))
         end
       )
    |> Enum.sort(
         fn p1, p2 ->
           Poker.Hand.compare_hand_score(p1.hand_score, p2.hand_score)
         end
       )
  end


  @doc """
  Some table state is privileged (cards remaining, pending actions, etc)
  This function takes the game state and converts it into state that can
  be sent to clients
  """
  def sanitize_table_state(table_state) do
    table_state
  end

end
