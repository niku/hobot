defmodule Hobot.Bot.Supervisor do
  use Supervisor

  def start_link(arg, options \\ []) do
    Supervisor.start_link(__MODULE__, arg, options)
  end

  def init(%{name: name, adapter: adapter, handlers: handlers}) do
    handlers_with_index = Enum.with_index(handlers)
    context = Hobot.Bot.make_context(name, adapter, handlers_with_index)
    children = [
      supervisor(Registry, [:duplicate, context.pub_sub]),
      supervisor(Agent, [fn -> context end, [name: context.context]]),
      supervisor(Task.Supervisor, [[name: context.task_supervisor]]),
      worker(GenServer, [adapter.module, build_args(adapter, context), build_options(adapter, context.adapter)], [id: context.adapter]),
    ] ++ for {handler, index} <- handlers_with_index do
      worker(GenServer, [handler.module, build_args(handler, context), build_options(adapter, apply(context.handler, [index]))], [id: apply(context.handler, [index])])
    end

    # NOTE: I think it's worth to add a process name. But I'm not sure how to make it.
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  def build_args(conf, context) do
    case Map.get(conf, :args, []) do
      [] -> context
      args -> List.to_tuple([context | args])
    end
  end

  def build_options(conf, name) do
    options = Map.get(conf, :options, [])
    Keyword.merge(options, [name: name])
  end
end
