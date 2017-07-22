defmodule Hobot.Bot do
  @name_prefix __MODULE__

  def build_name(name) do
    Module.concat(@name_prefix, name)
  end

  def bot(atom), do: build_name(atom)
  def context(atom), do: Module.concat(bot(atom), "Context")
  def task_supervisor(atom), do: Module.concat(bot(atom), "TaskSupervisor")
  def pub_sub(atom), do: Hobot.PubSub.build_name(bot(atom))
  def adapter(atom), do: Hobot.Adapter.build_name(bot(atom))
  def handler(atom, index), do: Hobot.Handler.build_name(bot(atom), index)
  def middleware(atom, adapter, handlers_with_index) do
    for {handler_conf, index} <- handlers_with_index, into: %{adapter(atom) => Hobot.Middleware.build(adapter)} do
      {handler(atom, index), Hobot.Middleware.build(handler_conf)}
    end
  end

  def subscribe(pub_sub, topic, middleware) do
    {:registered_name, registered_name} = Process.info(self(), :registered_name)
    before_receive = get_in(middleware, [Access.key!(registered_name), Access.key!(:before_receive)])
    Hobot.PubSub.subscribe(pub_sub, topic, before_receive)
  end

  def publish(pub_sub, topic, ref, data, task_supervisor, middleware) do
    {:registered_name, registered_name} = Process.info(self(), :registered_name)
    before_publish = get_in(middleware, [Access.key!(registered_name), Access.key!(:before_publish)])
    Hobot.PubSub.publish(pub_sub, topic, ref, data, task_supervisor, before_publish)
  end

  def reply(adapter_name, ref, data, task_supervisor, middleware) do
    {:registered_name, registered_name} = Process.info(self(), :registered_name)
    before_reply = get_in(middleware, [Access.key!(registered_name), Access.key!(:before_reply)])
    reply = {:reply, ref, data}
    Task.Supervisor.start_child(task_supervisor, fn ->
      case Hobot.Middleware.apply_middleware(before_reply, reply) do
        {:ok, value} ->
          GenServer.cast(adapter_name, value)
        {:halt, value} ->
          # TODO: Better Logging
          IO.inspect {:halt, value}
      end
    end)
  end

  def make_context(name, adapter, handlers_with_index) do
    middleware = middleware(name, adapter, handlers_with_index)
    %{
      bot: bot(name),
      context: context(name),
      task_supervisor: task_supervisor(name),
      pub_sub: pub_sub(name),
      adapter: adapter(name),
      handler: &(handler(name, &1)),
      middleware: middleware,
      subscribe: &(subscribe(pub_sub(name), &1, middleware)),
      publish: &(publish(pub_sub(name), &1, &2, &3, task_supervisor(name), middleware)),
      unsubscribe: &(Hobot.PubSub.unsubscribe(pub_sub(name), &1)),
      reply: &(reply(adapter(name), &1, &2, task_supervisor(name), middleware))
    }
  end

  def get_context(name) do
    Agent.get(context(name), &(&1))
  end
end
