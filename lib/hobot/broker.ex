defmodule Hobot.Broker do
  def start_link do
    Registry.start_link(:duplicate, __MODULE__, [partitions: System.schedulers_online()])
  end

  def subscribe(topic) do
    Registry.register(__MODULE__, topic, [])
  end

  def publish(topic, data) do
    message = {:broadcast, topic, data}
    Registry.dispatch(__MODULE__, topic, fn entries ->
      for {pid, _} <- entries, do: GenServer.cast(pid, message)
    end)
  end
end
