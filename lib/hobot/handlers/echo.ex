defmodule Hobot.Handlers.Echo do
  @moduledoc """
  Echoes input.
  """

  use GenServer

  def start_link({topic, context}, genserver_options \\ []) do
    GenServer.start_link(__MODULE__, {topic, context}, genserver_options)
  end

  def init({topic, context} = args) do
    context.subscribe.(topic)
    {:ok, args}
  end

  def handle_cast({:broadcast, from, ref, data}, state) do
    GenServer.cast(from, {ref, data})
    {:noreply, state}
  end

  def terminate(reason, {topic, context}) do
    context.unsubscribe.(topic)
    reason
  end
end
