defmodule HobotTest do
  use ExUnit.Case
  doctest Hobot

  @moduletag :capture_log

  defmodule CallbackSubscriber do
    use GenServer

    def start_link(args) do
      GenServer.start_link(__MODULE__, args)
    end

    def init({topic, callback_pid}) do
      Hobot.subscribe(topic)
      {:ok, callback_pid}
    end

    def handle_cast(message, callback_pid) do
      send(callback_pid, message)
      {:noreply, callback_pid}
    end

    def handle_call({:unsubscribe, topic}, _from, callback_pid) do
      Hobot.unsubscribe(topic)
      {:reply, :ok, callback_pid}
    end
  end

  defmodule CrashSubscriber do
    use GenServer

    def start_link(args) do
      GenServer.start_link(__MODULE__, args)
    end

    def init({topic, callback_pid}) do
      Hobot.subscribe(topic)
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

    def start_link(args) do
      GenServer.start_link(__MODULE__, args)
    end

    def init(topic) do
      Hobot.subscribe(topic)
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

    import Supervisor.Spec
    children = [
      worker(CallbackSubscriber, [], [])
    ]
    {:ok, sup_pid} = Supervisor.start_link(children, strategy: :simple_one_for_one)
    {:ok, _subscriber} = Supervisor.start_child(sup_pid, [{topic, self()}])

    data = "Hello world!"
    :ok = Hobot.publish(topic, data)
    assert_receive {:broadcast, ^topic, ^data}
  end

  test "A subscriber receives no message which was published to a topic which didn't subscribe" do
    topic = "foo"

    import Supervisor.Spec
    children = [
      worker(CallbackSubscriber, [], [])
    ]
    {:ok, sup_pid} = Supervisor.start_link(children, strategy: :simple_one_for_one)
    {:ok, _subscriber} = Supervisor.start_child(sup_pid, [{topic, self()}])

    data = "Hello world!"
    :ok = Hobot.publish("bar", data)
    refute_receive _anything
  end

  test "A subscriber receives no message if subscriber has unsubscrebed the topic" do
    topic = "foo"

    import Supervisor.Spec
    children = [
      worker(CallbackSubscriber, [], [])
    ]
    {:ok, sup_pid} = Supervisor.start_link(children, strategy: :simple_one_for_one)
    {:ok, subscriber} = Supervisor.start_child(sup_pid, [{topic, self()}])
    GenServer.call(subscriber, {:unsubscribe, topic})

    data = "Hello world!"
    :ok = Hobot.publish("bar", data)
    refute_receive _anything
  end

  test "A subscriber receives message even if other subscribers crashed" do
    topic = "foo"

    import Supervisor.Spec
    children = [
      worker(CrashSubscriber, [], [])
    ]
    {:ok, sup_pid} = Supervisor.start_link(children, strategy: :simple_one_for_one)
    {:ok, crashsubscriber} = Supervisor.start_child(sup_pid, [{topic, self()}])

    children = [
      worker(CallbackSubscriber, [], [])
    ]
    {:ok, sup_pid} = Supervisor.start_link(children, strategy: :simple_one_for_one)
    {:ok, _subscriber} = Supervisor.start_child(sup_pid, [{topic, self()}])

    data = "Hello world!"
    :ok = Hobot.publish(topic, data)
    assert_receive {:broadcast, ^topic, ^data}

    # Waiting for the process crashed
    receive do
      "terminated" ->
        Process.sleep(10)
        false = Process.alive?(crashsubscriber) # assume the process is not alive.
    end

    data = "Hello world again!"
    :ok = Hobot.publish(topic, data)
    assert_receive {:broadcast, ^topic, ^data}
  end

  test "A subscriber receives message with low latency even if other subscribers were slow" do
    topic = "foo"

    import Supervisor.Spec
    children = [
      worker(SlowSubscriber, [], [])
    ]
    {:ok, sup_pid} = Supervisor.start_link(children, strategy: :simple_one_for_one)
    {:ok, _slowscriber} = Supervisor.start_child(sup_pid, [topic])

    children = [
      worker(CallbackSubscriber, [], [])
    ]
    {:ok, sup_pid} = Supervisor.start_link(children, strategy: :simple_one_for_one)
    {:ok, _subscriber} = Supervisor.start_child(sup_pid, [{topic, self()}])

    for _times <- 1..1000 do
      data = "Hello world!"
      :ok = Hobot.publish(topic, data)
      assert_receive {:broadcast, ^topic, ^data}, 1 # timeout 1ms
    end
  end

  test "The broker eliminates crashed subscriber from own registry" do
    # See also
    # https://hexdocs.pm/elixir/1.4.2/Registry.html#module-registrations

    topic = "foo"

    import Supervisor.Spec
    children = [
      worker(CrashSubscriber, [], restart: :temporary)
    ]
    {:ok, sup_pid} = Supervisor.start_link(children, strategy: :simple_one_for_one)
    for _times <- 1..99 do
      {:ok, _crachsubscriber} = Supervisor.start_child(sup_pid, [{topic, self()}])
    end

    children = [
      worker(CallbackSubscriber, [], [])
    ]
    {:ok, sup_pid} = Supervisor.start_link(children, strategy: :simple_one_for_one)
    {:ok, _subscriber} = Supervisor.start_child(sup_pid, [{topic, self()}])

    100 = length(Registry.lookup(Hobot, topic))

    data = "Hello world!"
    :ok = Hobot.publish(topic, data)

    Process.sleep(10)

    assert length(Registry.lookup(Hobot, topic)) < 100
  end
end
