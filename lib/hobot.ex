defmodule Hobot do
  @moduledoc """
  A bot framework for ErlangVM(beam)
  """

  @broker Hobot.Broker

  def subscribe(topic) do
    Registry.register(@broker, topic, [])
  end

  def unsubscribe(topic) do
    Registry.unregister(@broker, topic)
  end

  def publish(topic, data) do
    Task.Supervisor.start_child(Hobot.TaskSupervisor, fn ->
      message = {:broadcast, topic, data}
      Registry.dispatch(@broker, topic, fn entries ->
        for {pid, _} <- entries do
          GenServer.cast(pid, message)
        end
      end)
    end)
  end
end
