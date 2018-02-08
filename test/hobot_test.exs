defmodule HobotTest do
  use ExUnit.Case
  doctest Hobot

  test "create a bot and it works well" do
    {:ok, io_device} = StringIO.open("")

    bot_name = "Foo"
    adapter = %{module: Hobot.Plugin.Adapter.Shell, args: [io_device]}
    handlers = [%{module: Hobot.Plugin.Handler.Echo, args: [["on_message"]]}]
    {:ok, bot_pid} = Hobot.create(bot_name, adapter, handlers)

    context = Hobot.context(bot_pid)
    adapter_pid = Hobot.pid(context.adapter)

    send(adapter_pid, "hello")
    # wait async io
    Process.sleep(10)
    assert StringIO.flush(io_device) == "\"hello\"\n"
  end
end
