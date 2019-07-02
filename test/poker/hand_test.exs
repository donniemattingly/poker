defmodule Poker.HandTest do
  use ExUnit.Case

  alias Poker.Hand

  @moduletag :capture_log

  doctest Hand

  test "module exists" do
    assert is_list(Hand.module_info())
  end

  test "convert shorthand" do
    assert Poker.Hand.convert_shorthand(["5S", "TD", "KC"]) == [{5, :spades}, {10, :diamonds}, {:k, :clubs}]
  end
end
