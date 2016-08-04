defmodule BeamHomunculus.Adapters.Shell do
  @moduledoc """
  Adapter between bot and shell
  """

  use BeamHomunculus.Adapter

  def input(_config \\ []) do
    stream = Stream.repeatedly(fn -> IO.gets "> " end)
    Stream.map(stream, &String.trim/1)
  end

  def output(message) do
    IO.puts message
  end
end
