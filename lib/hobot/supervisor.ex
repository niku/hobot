defmodule Hobot.Supervisor do
  use Supervisor

  def start_link(args) do
    map_as_args = Enum.into(args, Map.new)
    Supervisor.start_link(__MODULE__, map_as_args, name: __MODULE__)
  end

  def init(%{name_registry: _, task_supervisor: _} = args) do
    Supervisor.init([
      Supervisor.child_spec(Hobot.Bot.Supervisor, start: {Hobot.Bot.Supervisor, :start_link, [args]})
    ], strategy: :simple_one_for_one)
  end
end
