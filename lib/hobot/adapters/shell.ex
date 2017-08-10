defmodule Hobot.Adapters.Shell do
  @moduledoc """
  Adapts stdio for hobot.
  """

  use GenServer

  def gets(device \\ :stdio, prompt, send_to) do
    with x when is_binary(x) <- IO.gets(device, prompt),
         line when line !== "quit" <- String.trim_trailing(x) do
      send(send_to, line)
      gets(device, prompt, send_to)
    else
      _ ->
        nil
    end
  end

  def handle_cast({:reply, _ref, data}, {_context, device} = state) do
    IO.puts(device, inspect(data))
    {:noreply, state}
  end

  def handle_info(data, {context, _device} = state) do
    apply(context.publish, ["on_message", make_ref(), data])
    {:noreply, state}
  end
end
