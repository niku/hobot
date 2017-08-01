defmodule Hobot.Bot.Supervisor do
  use Supervisor

  def start_link(env, arg, options \\ []) do
    Supervisor.start_link(__MODULE__, Map.merge(env, arg), options)
  end

  def init(%{name: name, adapter: adapter, handlers: handlers, name_registry: name_registry, pub_sub: pub_sub, task_supervisor: task_supervisor}) do
    handlers_with_index = Enum.with_index(handlers)
    context = Hobot.Bot.make_context(name, adapter, handlers_with_index, name_registry, pub_sub, task_supervisor)
    children = [
      %{
        id: context.context,
        start: {Agent, :start_link, [fn -> context end, [name: build_via_name(context.name_registry, context.context)]]}
      },
      %{
        id: context.adapter,
        start: {GenServer, :start_link, [adapter.module, build_args(adapter, context), build_options(adapter, context, context.adapter)]}
      }
    ] ++ for {handler, index} <- handlers_with_index do
      %{
        id: apply(context.handler, [index]),
        start: {GenServer, :start_link, [handler.module, build_args(handler, context), build_options(handler, context, apply(context.handler, [index]))]}
      }
    end

    opts = [strategy: :one_for_one]
    Supervisor.init(children, opts)
  end

  def build_args(conf, context) do
    case Map.get(conf, :args, []) do
      [] -> context
      args -> List.to_tuple([context | args])
    end
  end

  def build_options(conf, context, name) do
    options = Map.get(conf, :options, [])
    Keyword.merge(options, name: build_via_name(context.name_registry, name))
  end

  def build_via_name(name_registry, name), do: {:via, Registry, {name_registry, name}}
end
