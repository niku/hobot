defmodule Hobot.Bot.Supervisor do
  use Supervisor

  def start_link(arg, options \\ []) do
    Supervisor.start_link(__MODULE__, arg, options)
  end

  def init(%{name: name, adapter: adapter, handlers: handlers}) do
    context = Hobot.Bot.make_context(name)
    children = [
      supervisor(Registry, [:duplicate, context.pub_sub]),
      # Right now, I don't implement to take a GenServer options because of I don't need it.
      # If you want give a GenServer options from outside, feel free to make a pull request.
      worker(GenServer, [adapter.module, build_args(adapter, context), [name: context.adapter]]),
    ] ++ build_handlers(handlers, context)

    # NOTE: It's worth to add a process name. I couldn't it right now.
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  def build_args(conf, context) do
    case Map.get(conf, :args, []) do
      [] -> context
      args -> {context, args}
    end
  end

  def build_handlers(handlers, context) do
    for {handler, index} <- Enum.with_index(handlers) do
      worker(GenServer, [handler.module, build_args(handler, context)], [id: "Handler#{index}"])
    end
  end
end
