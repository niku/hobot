defmodule HobotTest do
  use ExUnit.Case
  doctest Hobot

  @moduletag :capture_log

  defmodule CallbackSubscriber do
    use GenServer

    def init({topic, callback_pid}) do
      Hobot.subscribe(1, topic)
      {:ok, callback_pid}
    end

    def handle_cast(message, callback_pid) do
      send(callback_pid, message)
      {:noreply, callback_pid}
    end
  end

  defmodule CrashSubscriber do
    use GenServer

    def init({topic, callback_pid}) do
      Hobot.subscribe(1, topic)
      {:ok, callback_pid}
    end

    def handle_cast(_message, callback_pid) do
      exit(:boom!)
      {:noreply, callback_pid}
    end

    def terminate(_reason, callback_pid) do
      send(callback_pid, "terminated")
      :shutdown
    end
  end

  defmodule SlowSubscriber do
    use GenServer

    def init(topic) do
      Hobot.subscribe(1, topic)
      {:ok, []}
    end

    def handle_cast(_message, state) do
      Process.sleep(1000)
      {:noreply, state}
    end
  end

  setup do
    Application.stop(:hobot)
    :ok = Application.start(:hobot)
  end

  test "A subscriber receives message which was published to a topic which subscribed" do
    topic = "foo"
    {:ok, _subscriber} = GenServer.start_link(CallbackSubscriber, {topic, self()})

    data = "Hello world!"
    :ok = Hobot.publish(1, topic, data)
    assert_receive {:broadcast, ^topic, ^data}
  end

  test "A subscriber receives no message which was published to a topic which didn't subscribe" do
    topic = "foo"
    {:ok, _subscriber} = GenServer.start_link(CallbackSubscriber, {topic, self()})

    data = "Hello world!"
    :ok = Hobot.publish(1, "bar", data)
    refute_receive _anything
  end

  test "A subscriber receives message even if other subscribers crashed" do
    topic = "foo"
    {:ok, crashsubscriber} = GenServer.start(CrashSubscriber, {topic, self()})
    {:ok, _subscriber} = GenServer.start_link(CallbackSubscriber, {topic, self()})

    data = "Hello world!"
    :ok = Hobot.publish(1, topic, data)
    assert_receive {:broadcast, ^topic, ^data}

    # Waiting for the process crashed
    receive do
      "terminated" ->
        Process.sleep(10)
        false = Process.alive?(crashsubscriber) # assume the process is not alive.
    end

    data = "Hello world again!"
    :ok = Hobot.publish(1, topic, data)
    assert_receive {:broadcast, ^topic, ^data}
  end

  test "A subscriber receives message with low latency even if other subscribers were slow" do
    topic = "foo"
    {:ok, _slowsubscriber} = GenServer.start_link(SlowSubscriber, topic)
    {:ok, _subscriber} = GenServer.start_link(CallbackSubscriber, {topic, self()})

    for _times <- 1..1000 do
      data = "Hello world!"
      :ok = Hobot.publish(1, topic, data)
      assert_receive {:broadcast, ^topic, ^data}, 1 # timeout 1ms
    end
  end

  test "The broker eliminates crashed subscriber from own registry" do
    # See also
    # https://hexdocs.pm/elixir/1.4.2/Registry.html#module-registrations

    topic = "foo"
    for _times <- 1..99 do
      {:ok, _crashsubscriber} = GenServer.start(CrashSubscriber, {topic, self()})
    end
    {:ok, _subscriber} = GenServer.start_link(CallbackSubscriber, {topic, self()})

    100 = length(Registry.lookup(Hobot, topic))

    data = "Hello world!"
    :ok = Hobot.publish(1, topic, data)

    Process.sleep(10)

    assert length(Registry.lookup(Hobot, topic)) < 100
  end
end
