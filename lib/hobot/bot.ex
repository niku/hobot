defmodule Hobot.Bot do
  def context(name), do: Enum.join([name, "Context"], ".")
  def adapter(name), do: Enum.join([name, "Adapter"], ".")
  def handler(name, index), do: Enum.join([name, "Handler#{index}"], ".")
  def middleware(atom, adapter, handlers_with_index) do
    for {handler_conf, index} <- handlers_with_index, into: %{adapter(atom) => Hobot.Middleware.build(adapter)} do
      {handler(atom, index), Hobot.Middleware.build(handler_conf)}
    end
  end

  def subscribe(%Hobot.ApplicationProcess{} = application_process, name, topic, middleware) do
    [registered_name] = Registry.keys(application_process.name_registry, self())
    before_receive = get_in(middleware, [Access.key!(registered_name), Access.key!(:before_receive)])
    Hobot.PubSub.subscribe(application_process, name, topic, before_receive)
  end

  def publish(%Hobot.ApplicationProcess{} = application_process, name, topic, ref, data, middleware) do
    [registered_name] = Registry.keys(application_process.name_registry, self())
    before_publish = get_in(middleware, [Access.key!(registered_name), Access.key!(:before_publish)])
    Hobot.PubSub.publish(application_process, name, topic, ref, data, before_publish)
  end

  def reply(%Hobot.ApplicationProcess{} = application_process, adapter_name, ref, data, middleware) do
    [registered_name] = Registry.keys(application_process.name_registry, self())
    before_reply = get_in(middleware, [Access.key!(registered_name), Access.key!(:before_reply)])
    reply = {:reply, ref, data}
    Task.Supervisor.start_child(application_process.task_supervisor, fn ->
      case Hobot.Middleware.apply_middleware(before_reply, reply) do
        {:ok, value} ->
          GenServer.cast({:via, Registry, {application_process.name_registry, adapter_name}}, value)
        {:halt, value} ->
          # TODO: Better Logging
          IO.inspect {:halt, value}
      end
    end)
  end

  def make_context(name, adapter, handlers_with_index, %Hobot.ApplicationProcess{} = application_process) do
    middleware = middleware(name, adapter, handlers_with_index)
    %{
      context: context(name),
      task_supervisor: application_process.task_supervisor,
      name_registry: application_process.name_registry,
      pub_sub: application_process.pub_sub,
      adapter: adapter(name),
      handler: &(handler(name, &1)),
      middleware: middleware,
      subscribe: &(subscribe(application_process, name, &1, middleware)),
      publish: &(publish(application_process, name, &1, &2, &3, middleware)),
      unsubscribe: &(Hobot.PubSub.unsubscribe(application_process.pub_sub, name, &1)),
      reply: &(reply(application_process, adapter(name), &1, &2, middleware))
    }
  end

  def get_context(name) do
    Agent.get({:via, Registry, {Hobot.NameRegistry, context(name)}}, &(&1))
  end
end
