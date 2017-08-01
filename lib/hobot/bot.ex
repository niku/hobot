defmodule Hobot.Bot do
  @name_prefix __MODULE__

  def build_name(name) do
    Module.concat(@name_prefix, name)
  end

  def bot(atom), do: build_name(atom)
  def context(atom), do: Module.concat(bot(atom), "Context")
  def adapter(atom), do: Hobot.Adapter.build_name(bot(atom))
  def handler(atom, index), do: Hobot.Handler.build_name(bot(atom), index)
  def middleware(atom, adapter, handlers_with_index) do
    for {handler_conf, index} <- handlers_with_index, into: %{adapter(atom) => Hobot.Middleware.build(adapter)} do
      {handler(atom, index), Hobot.Middleware.build(handler_conf)}
    end
  end

  def subscribe(pub_sub, name, topic, name_registry, middleware) do
    [registered_name] = Registry.keys(name_registry, self())
    before_receive = get_in(middleware, [Access.key!(registered_name), Access.key!(:before_receive)])
    Hobot.PubSub.subscribe(pub_sub, name, topic, before_receive)
  end

  def publish(pub_sub, name, topic, ref, data, name_registry, task_supervisor, middleware) do
    [registered_name] = Registry.keys(name_registry, self())
    before_publish = get_in(middleware, [Access.key!(registered_name), Access.key!(:before_publish)])
    Hobot.PubSub.publish(pub_sub, name, topic, ref, data, task_supervisor, before_publish)
  end

  def reply(adapter_name, ref, data, name_registry, task_supervisor, middleware) do
    [registered_name] = Registry.keys(name_registry, self())
    before_reply = get_in(middleware, [Access.key!(registered_name), Access.key!(:before_reply)])
    reply = {:reply, ref, data}
    Task.Supervisor.start_child(task_supervisor, fn ->
      case Hobot.Middleware.apply_middleware(before_reply, reply) do
        {:ok, value} ->
          GenServer.cast({:via, Registry, {name_registry, adapter_name}}, value)
        {:halt, value} ->
          # TODO: Better Logging
          IO.inspect {:halt, value}
      end
    end)
  end

  def make_context(name, adapter, handlers_with_index, name_registry, pub_sub, task_supervisor) do
    middleware = middleware(name, adapter, handlers_with_index)
    %{
      bot: bot(name),
      context: context(name),
      task_supervisor: task_supervisor,
      name_registry: name_registry,
      pub_sub: pub_sub,
      adapter: adapter(name),
      handler: &(handler(name, &1)),
      middleware: middleware,
      subscribe: &(subscribe(pub_sub, bot(name), &1, name_registry, middleware)),
      publish: &(publish(pub_sub, bot(name), &1, &2, &3, name_registry, task_supervisor, middleware)),
      unsubscribe: &(Hobot.PubSub.unsubscribe(pub_sub, bot(name), &1)),
      reply: &(reply(adapter(name), &1, &2, name_registry, task_supervisor, middleware))
    }
  end

  def get_context(name) do
    Agent.get({:via, Registry, {Hobot.NameRegistry, context(name)}}, &(&1))
  end
end
