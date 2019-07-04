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

  test "converts cards to int" do
    hexString =
      ~w"AH TD 7C"
      |> Hand.from_shorthand()
      |> Hand.cards_to_comparable_int()
      |> Integer.to_string(16)

    assert hexString === "EA7"
  end

  test "Ace ten kicker beats Ace nine" do
    aceTen = ~w"AH TD"
    aceNine = ~w"AH 9D"

    a10score =
      aceTen
      |> Hand.from_shorthand()
      |> Hand.cards_to_comparable_int()

    a9score =
      aceNine
      |> Hand.from_shorthand()
      |> Hand.cards_to_comparable_int()

    assert a10score > a9score
  end
end
