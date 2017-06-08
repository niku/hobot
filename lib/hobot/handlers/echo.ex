defmodule Hobot.Handlers.Echo do
  @moduledoc """
  Echoes input.
  """

  use GenServer

  def start_link({topic, handler_options}, genserver_options \\ []) do
    GenServer.start_link(__MODULE__, {topic, handler_options}, genserver_options)
  end

  def init({topic, _handler_options} = args) do
    Hobot.PubSub.subscribe(topic)
    {:ok, args}
  end

  def handle_cast({:broadcast, from, ref, data}, state) do
    GenServer.cast(from, {ref, data})
    {:noreply, state}
  end

  def terminate(reason, {topic, _handler_options}) do
    Hobot.PubSub.unsubscribe(topic)
    reason
  end
end
