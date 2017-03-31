defmodule Hobot.Bot do
  @moduledoc """
  A bot server
  """

  use GenServer

  def start_link(%Hobot.BotSupervisor.Config{} = config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def input(message) do
    # TODO handler & action
    output(message)
  end

  def output(message) do
    GenServer.cast(__MODULE__, {:output, message})
  end

  def handle_cast({:output, message}, %Hobot.BotSupervisor.Config{adapter: adapter} = state) do
    adapter.do_output(message)
    {:noreply, state}
  end
end
