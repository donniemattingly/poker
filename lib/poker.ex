defmodule Poker do
  use Application

  def start(_type, _args) do
    Poker.Supervisor.start_link(name: Poker.Supervisor)
  end
end
