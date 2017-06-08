defmodule Hobot.Adapters.Shell do
  @moduledoc """
  Adapts stdio for hobot.
  You can use following like:

  ```
  iex(1)> {:ok, pid} = Hobot.Adapters.Shell.start_link({"a_topic", []})
  {:ok, #PID<0.192.0>}
  iex(2)> Hobot.Adapters.Shell.gets(pid)
  > hi
  > how are youL?
  > quit
  nil
  iex(3)>
  ```
  """

  use GenServer

  @default_prompt "> "

  def gets(pid, prompt \\ @default_prompt) do
    line =
      IO.gets(prompt)
      |> String.trim_trailing
    case line do
      "quit" ->
        # Don't continue, just finish.
        nil
      _ ->
        send(pid, line)
        gets(pid)
    end
  end

  def start_link({topic, adapter_options}, genserver_options \\ []) do
    GenServer.start_link(__MODULE__, {topic, adapter_options}, genserver_options)
  end

  def handle_cast({_ref, data}, state) do
    IO.puts(inspect(data))
    {:noreply, state}
  end

  def handle_info(data, {topic, _options} = state) do
    from = self()
    ref = make_ref()
    Hobot.PubSub.publish(topic, from, ref, data)
    {:noreply, state}
  end
end
