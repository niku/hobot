defmodule Hobot.PubSub do
  def subscribe(%Hobot.ApplicationProcess{} = application_process, %Hobot.Topic{} = topic, before_receive) do
    Registry.register(application_process.pub_sub, topic, before_receive)
  end

  def unsubscribe(%Hobot.ApplicationProcess{} = application_process, %Hobot.Topic{} = topic) do
    Registry.unregister(application_process.pub_sub, topic)
  end

  def publish(%Hobot.ApplicationProcess{} = application_process, %Hobot.Topic{} = topic, ref, data, before_publish) do
    message = {:broadcast, topic.value, ref, data}
    Task.Supervisor.start_child(application_process.task_supervisor, fn ->
      case Hobot.Middleware.apply_middleware(before_publish, message) do
        {:ok, value} ->
          Registry.dispatch(application_process.pub_sub, topic, fn entries ->
            for {pid, before_receive} <- entries do
              Task.Supervisor.start_child(application_process.task_supervisor, fn ->
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
