defmodule Hobot.Plugin.Handler.Logger do
  @moduledoc """
  Loggings input.
  """

  use GenServer
  require Logger

  def init({context, topics} = args) do
    for topic <- topics, do: apply(context.subscribe, [topic])
    {:ok, args}
  end

  def handle_cast({:broadcast, _topic, _ref, _data} = message, state) do
    Logger.info(inspect(message))
    {:noreply, state}
  end

  def terminate(reason, {context, topics}) do
    for topic <- topics, do: apply(context.unsubscribe, [topic])
    reason
  end
end
