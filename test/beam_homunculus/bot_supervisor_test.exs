defmodule BeamHomunculus.BotSupervisorTest do
  use ExUnit.Case

  test "starts and stops a bot server" do
    config = %BeamHomunculus.BotSupervisor.Config{}
    {:ok, pid} = BeamHomunculus.BotSupervisor.start_link(config)
    :ok = Supervisor.stop(pid)
    refute Process.alive?(pid)
  end
end
