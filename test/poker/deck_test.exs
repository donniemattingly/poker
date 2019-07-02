defmodule Poker.DeckTest do
  use ExUnit.Case

  alias Poker.Deck

  @moduletag :capture_log

  doctest Poker.Deck

  test "module exists" do
    assert is_list(Poker.Deck.module_info())
  end

  test "deals 52 cards" do
    assert length(Poker.Deck.new) == 52
  end

  test "shuffles deck" do
    matches = Enum.zip(Poker.Deck.shuffle, Poker.Deck.shuffle)
    |> Enum.map(fn ({{r1, s1}, {r2, s2}}) -> r1 == r2 && s1 == s2 end)
    |> Enum.filter(&(&1))
    assert length(matches) < 52
  end
end
