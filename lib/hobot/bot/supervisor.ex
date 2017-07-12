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
      worker(GenServer, [adapter.module, build_args(adapter, context), [name: context.adapter]], [id: context.adapter]),
    ] ++ for {handler, index} <- Enum.with_index(handlers) do
      worker(GenServer, [handler.module, build_args(handler, context), [name: context.handler.(index)]], [id: context.handler.(index)])
    end

    # NOTE: I think it's worth to add a process name. But I'm not sure how to make it.
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  def build_args(conf, context) do
    case Map.get(conf, :args, []) do
      [] -> context
      args -> {context, args}
    end
  end
end
