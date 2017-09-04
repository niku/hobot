defmodule Hobot.Plugin.Handler.Echo do
  @moduledoc """
  Echoes input.
  """

  use GenServer

  def init({context, topics} = args) do
    for topic <- topics, do: apply(context.subscribe, [topic])
    {:ok, args}
  end

  def handle_cast({:broadcast, _topic, ref, data}, {context, _topics} = state) do
    apply(context.reply, [ref, data])
    {:noreply, state}
  end

  def terminate(reason, {context, topics}) do
    for topic <- topics, do: apply(context.unsubscribe, [topic])
    reason
  end
end
