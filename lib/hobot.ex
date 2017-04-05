defmodule Hobot do
  @moduledoc """
  A bot framework for ErlangVM(beam)
  """

  @messaging_definition_version 1

  def start_link do
    Registry.start_link(:duplicate, __MODULE__, [partitions: System.schedulers_online()])
  end

  def subscribe(expect_messageing_definition_version, topic) when expect_messageing_definition_version <= @messageing_definition_version do
    Registry.register(__MODULE__, topic, expect_messageing_definition_version)
  end

  def publish(expect_messageing_definition_version, topic, data) when expect_messageing_definition_version <= @messageing_definition_version do
    Registry.dispatch(__MODULE__, topic, fn entries ->
      for {pid, expect_messageing_definition_version} <- entries do
        case expect_messageing_definition_version do
          # For backward compatibility, It will be added if messaging definition is updated.
          1 ->
            message = {:broadcast, topic, data}
            GenServer.cast(pid, message)
        end
      end
    end)
  end
end
