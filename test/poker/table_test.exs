defmodule Poker.TableTest do
  use ExUnit.Case

  alias Poker.Table

  @moduletag :capture_log

  doctest Poker.Table

  def random_player do
    %{
      name: :crypto.strong_rand_bytes(4) |> Base.encode16
    }
  end

  setup do
    {:ok, table} = Poker.Table.start_table()
    {:ok, table: table}
  end

  test "can add player to table", context do
    sample_player = %{name: "test_player"}
    {reply, _} = Poker.Table.join_table(context[:table], sample_player)

    assert reply == :joined_table
  end

  test "two or more players trigger hand setup", context do
    s1 = random_player()
    s2 = random_player()
    table = context[:table]


    Poker.Table.join_table(table, s1)
    assert Poker.Table.get_state(table) == :waiting_for_players

    Poker.Table.join_table(table, s2)
    assert Poker.Table.get_state(table) != :waiting_for_players
  end

end
