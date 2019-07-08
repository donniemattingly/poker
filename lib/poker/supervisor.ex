defmodule Poker.Supervisor do
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, :ok, arg)
  end

  def init(:ok) do
    children = [
      {Registry, keys: :unique, name: :account_process_registry},
#      {Poker.Table, name: Poker.Table},
      {DynamicSupervisor, name: Poker.PlayerSupervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
