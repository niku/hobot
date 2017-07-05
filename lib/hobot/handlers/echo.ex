defmodule Hobot.Handlers.Echo do
  @moduledoc """
  Echoes input.
  """

  use GenServer

  def init({topics, context} = args) do
    for topic <- topics, do: context.subscribe.(topic)
    {:ok, args}
  end

  def handle_cast({:broadcast, _topic, from, ref, data}, state) do
    GenServer.cast(from, {ref, data})
    {:noreply, state}
  end

  def terminate(reason, {topics, context}) do
    for topic <- topics, do: context.unsubscribe.(topic)
    reason
  end
end
