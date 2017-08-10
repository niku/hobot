defmodule Hobot.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    Supervisor.init([
      Supervisor.child_spec(Hobot.Bot.Supervisor, start: {Hobot.Bot.Supervisor, :start_link, []})
    ], strategy: :simple_one_for_one)
  end
end
