defmodule Hobot.Bot.Supervisor do
  use Supervisor

  def start_link(arg, options \\ []) do
    Supervisor.start_link(__MODULE__, arg, options)
  end

  def init(arg) do
    context = Hobot.Bot.make_context(arg)
    children = [
      supervisor(Registry, [:duplicate, context.pub_sub]),
      # Right now, I don't implement to take a GenServer options because of I don't need it.
      # If you want give a GenServer options from outside, feel free to make a pull request.
      worker(GenServer, [Hobot.Adapters.Shell, context, [name: context.adapter]]),
      worker(GenServer, [Hobot.Handlers.Echo, {["on_message"], context}], [id: Handler])
    ]

    # NOTE: It's worth to add a process name. I couldn't it right now.
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
