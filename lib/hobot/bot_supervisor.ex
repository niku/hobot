defmodule Hobot.BotSupervisor do
  use Supervisor

  defmodule Config do
    @moduledoc """
    A config for a bot server
    """

    defstruct adapter: Hobot.Adapters.Shell, brain: nil, handler: [], action: []
  end

  def start_link(config = %Config{}) do
    Supervisor.start_link(__MODULE__, config)
  end

  def init(config) do
    children = [
      worker(Hobot.Bot, [config]),
      worker(Task, [Stream, :run, [config.adapter.do_input([])]])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
