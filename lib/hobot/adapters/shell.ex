defmodule Hobot.Adapters.Shell do
  @moduledoc """
  Adapts stdio for hobot.
  """

  use GenServer

  @default_prompt "> "

  def gets(send_to, prompt \\ @default_prompt) do
    line =
      IO.gets(prompt)
      |> String.trim_trailing
    case line do
      "quit" ->
        # Don't continue, just finish.
        nil
      _ ->
        send(send_to, line)
        gets(send_to, prompt)
    end
  end

  def handle_cast({_ref, data}, state) do
    IO.puts(inspect(data))
    {:noreply, state}
  end

  def handle_info(data, context) do
    from = self()
    ref = make_ref()
    context.publish.("on_message", from, ref, data)
    {:noreply, context}
  end
end
