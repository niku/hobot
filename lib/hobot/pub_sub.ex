defmodule Hobot.PubSub do
  def subscribe(registry, name, topic, before_receive) do
    Registry.register(registry, {name, topic}, before_receive)
  end

  def unsubscribe(registry, name, topic) do
    Registry.unregister(registry, {name, topic})
  end

  def publish(registry, name, topic, ref, data, task_supervisor, before_publish) do
    message = {:broadcast, topic, ref, data}
    Task.Supervisor.start_child(task_supervisor, fn ->
      case Hobot.Middleware.apply_middleware(before_publish, message) do
        {:ok, value} ->
          Registry.dispatch(registry, {name, topic}, fn entries ->
            for {pid, before_receive} <- entries do
              Task.Supervisor.start_child(task_supervisor, fn ->
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
