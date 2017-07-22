defmodule Hobot.PubSub do
  @name_suffix PubSub

  def build_name(bot_name) do
    Module.concat(bot_name, @name_suffix)
  end

  def subscribe(registry, topic, before_receive) do
    Registry.register(registry, topic, before_receive)
  end

  def unsubscribe(registry, topic) do
    Registry.unregister(registry, topic)
  end

  def publish(registry, topic, ref, data, before_publish) do
    message = {:broadcast, topic, ref, data}
    Task.start(fn ->
      case Hobot.Middleware.apply_middleware(before_publish, message) do
        {:ok, value} ->
          Registry.dispatch(registry, topic, fn entries ->
            for {pid, before_receive} <- entries do
              # TODO: Make supervised task
              Task.start(fn ->
                case Hobot.Middleware.apply_middleware(before_receive, value) do
                  {:ok, value} ->
                    GenServer.cast(pid, value)
                  {:halt, value} ->
                    # TODO: Better Logging
                    IO.inspect {:halt, value}
                end
              end)
            end
          end)
        {:halt, value} ->
          # TODO: Better Logging
          IO.inspect {:halt, value}
      end
    end)
  end
end
