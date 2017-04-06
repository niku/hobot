defmodule Hobot do
  @moduledoc """
  A bot framework for ErlangVM(beam)
  """

  def start_link do
    Registry.start_link(:duplicate, __MODULE__, [partitions: System.schedulers_online()])
  end

  def subscribe(api_version, topic) when api_version === 1 do
    Registry.register(__MODULE__, topic, api_version)
  end

  def publish(api_version, topic, data) when api_version === 1 do
    Registry.dispatch(__MODULE__, topic, fn entries ->
      for {pid, api_version_on_subscribe} <- entries do
        case api_version_on_subscribe do
          # For backward compatibility,
          # version numbers is going to be added if messaging definition is updated.
          1 ->
            message = {:broadcast, topic, data}
            GenServer.cast(pid, message)
        end
      end
    end)
  end
end
