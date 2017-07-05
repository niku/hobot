defmodule Hobot.PubSub do
  @name_suffix PubSub

  def build_name(bot_name) do
    Module.concat(bot_name, @name_suffix)
  end

  def subscribe(registry, topic) do
    Registry.register(registry, topic, [])
  end

  def unsubscribe(registry, topic) do
    Registry.unregister(registry, topic)
  end

  def publish(registry, topic, from, ref, data) do
    message = {:broadcast, topic, from, ref, data}
    Registry.dispatch(registry, topic, fn entries ->
      for {pid, _} <- entries do
        GenServer.cast(pid, message)
      end
    end)
  end
end
