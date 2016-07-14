defmodule BeamHomunculus.Commands do
  @moduledoc """
  This module contains functions as command
  """

  def help() do
    IO.puts "hello" # TODO
  end

  def generate() do
    IO.puts "generate" # TODO
  end

  def run(_args) do
    config = %BeamHomunculus.BotSupervisor.Config{}
    {:ok, pid} = Supervisor.start_child(BeamHomunculus.Supervisor, [config])
    IO.puts "run: #{inspect pid}"
    Process.sleep(:infinity)
  end
end
