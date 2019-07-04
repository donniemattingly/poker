defmodule Poker.HandTest do
  use ExUnit.Case

  alias Poker.Hand

  @moduletag :capture_log

  doctest Hand

  test "module exists" do
    assert is_list(Hand.module_info())
  end

  test "convert shorthand" do
    assert Hand.from_shorthand(~w"5S TD KC") == [
             {5, :spades},
             {10, :diamonds},
             {:k, :clubs}
           ]
  end

  test "comparable int" do
    hexString = ~w"AH TD 7C"
                |> Hand.from_shorthand
                |> Hand.cards_to_comparable_int
                |> Integer.to_string(16)

    assert hexString === "EA7"
  end
end
