defmodule Hobot.BotSupervisorTest do
  use ExUnit.Case

  test "starts and stops a bot server" do
    config = %Hobot.BotSupervisor.Config{}
    {:ok, pid} = Hobot.BotSupervisor.start_link(config)
    :ok = Supervisor.stop(pid)
    refute Process.alive?(pid)
  end
end
