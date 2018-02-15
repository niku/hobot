defmodule Hobot.Supervisor do
  @moduledoc false

  use DynamicSupervisor

  def start_link([]) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_child(arg) do
    spec = Supervisor.Spec.worker(Hobot.Bot.Supervisor, [arg])
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
