defmodule Hobot do
  @moduledoc """
  A bot framework for ErlangVM(beam)
  """

  def subscribe(topic) do
    Registry.register(__MODULE__, topic, [])
  end

  def unsubscribe(topic) do
    Registry.unregister(__MODULE__, topic)
  end

  def publish(topic, data) do
    message = {:broadcast, topic, data}
    Registry.dispatch(__MODULE__, topic, fn entries ->
      for {pid, _} <- entries do
        GenServer.cast(pid, message)
      end
    end)
  end
end
