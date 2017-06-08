defmodule Hobot.PubSubTest do
  use ExUnit.Case
  doctest Hobot.PubSub

  @moduletag :capture_log

  defmodule CallbackSubscriber do
    use GenServer

    def start_link(args) do
      GenServer.start_link(__MODULE__, args)
    end

    def init({topic, _filters, _callback_pid} = args) do
      Hobot.PubSub.subscribe(topic)
      {:ok, args}
    end

    def handle_cast({:broadcast, pid, ref, data}, {_subscribed_topic, filters, callback_pid} = state) do
      filtered_message = Enum.reduce(filters, data, fn
        (f, acc) when is_function(f) ->
          apply(f, [acc])
        ({module, function, default_args}, acc) when is_atom(module) and is_atom(function) and is_list(default_args) ->
          apply(module, function, default_args ++ [acc])
      end)
      send(callback_pid, {:broadcast, pid, ref, filtered_message})
      {:noreply, state}
    end

    def handle_call({:unsubscribe, topic}, _from, callback_pid) do
      Hobot.PubSub.unsubscribe(topic)
      {:reply, :ok, callback_pid}
    end
  end

  defmodule CrashSubscriber do
    use GenServer

    def start_link(args) do
      GenServer.start_link(__MODULE__, args)
    end

    def init({topic, callback_pid}) do
      Hobot.PubSub.subscribe(topic)
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
      Hobot.PubSub.subscribe(topic)
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

    import Supervisor.Spec
    {:ok, callback_sup} = Supervisor.start_link([worker(CallbackSubscriber, [], [])], strategy: :simple_one_for_one)
    {:ok, crash_sup} = Supervisor.start_link([worker(CrashSubscriber, [], [])], strategy: :simple_one_for_one)
    {:ok, slow_sup} = Supervisor.start_link([worker(SlowSubscriber, [], [])], strategy: :simple_one_for_one)

    {:ok, [callback_sup: callback_sup, crash_sup: crash_sup, slow_sup: slow_sup]}
  end

  test "A subscriber receives filterd message which was published to a topic which subscribed", %{callback_sup: callback_sup} do
    topic = "foo"
    {:ok, _subscriber} = Supervisor.start_child(callback_sup, [{topic, [fn m -> "***" <> m  end], self()}])

    pid = self()
    ref = make_ref()
    data = "Hello world!"
    :ok = Hobot.PubSub.publish(topic, pid, ref, data)
    assert_receive {:broadcast, ^pid, ^ref, "***Hello world!"}
  end

  test "A subscriber receives no message which was published to a topic which didn't subscribe", %{callback_sup: callback_sup} do
    topic = "foo"
    {:ok, _subscriber} = Supervisor.start_child(callback_sup, [{topic, [], self()}])

    pid = self()
    ref = make_ref()
    data = "Hello world!"
    :ok = Hobot.PubSub.publish("bar", pid, ref, data)
    refute_receive _anything
  end

  test "A subscriber receives no message if subscriber has unsubscrebed the topic", %{callback_sup: callback_sup} do
    topic = "foo"
    {:ok, subscriber} = Supervisor.start_child(callback_sup, [{topic, [], self()}])
    GenServer.call(subscriber, {:unsubscribe, topic})

    pid = self()
    ref = make_ref()
    data = "Hello world!"
    :ok = Hobot.PubSub.publish("bar", pid, ref, data)
    refute_receive _anything
  end

  test "A subscriber receives message even if other subscribers crashed", %{callback_sup: callback_sup, crash_sup: crash_sup} do
    topic = "foo"

    {:ok, crashsubscriber} = Supervisor.start_child(crash_sup, [{topic, self()}])
    {:ok, _subscriber} = Supervisor.start_child(callback_sup, [{topic, [], self()}])

    pid = self()
    ref = make_ref()
    data = "Hello world!"
    :ok = Hobot.PubSub.publish(topic, pid, ref, data)
    assert_receive {:broadcast, ^pid, ^ref, ^data}

    # Waiting for the process crashed
    receive do
      "terminated" ->
        Process.sleep(10)
        false = Process.alive?(crashsubscriber) # assume the process is not alive.
    end

    data = "Hello world again!"
    :ok = Hobot.PubSub.publish(topic, pid, ref, data)
    assert_receive {:broadcast, ^pid, ^ref, ^data}
  end

  test "A subscriber receives message with low latency even if other subscribers were slow", %{callback_sup: callback_sup, slow_sup: slow_sup} do
    topic = "foo"

    {:ok, _slowscriber} = Supervisor.start_child(slow_sup, [topic])
    {:ok, _subscriber} = Supervisor.start_child(callback_sup, [{topic, [], self()}])

    for _times <- 1..1000 do
      pid = self()
      ref = make_ref()
      data = "Hello world!"
      :ok = Hobot.PubSub.publish(topic, pid, ref, data)
      assert_receive {:broadcast, ^pid, ^ref, ^data}, 1 # timeout 1ms
    end
  end

  test "The broker eliminates crashed subscriber from own registry", %{callback_sup: callback_sup}  do
    # See also
    # https://hexdocs.pm/elixir/1.4.2/Registry.html#module-registrations

    topic = "foo"

    import Supervisor.Spec
    children = [
      # Note: `restart: :temporary`
      worker(CrashSubscriber, [], restart: :temporary)
    ]
    {:ok, sup_pid} = Supervisor.start_link(children, strategy: :simple_one_for_one)
    for _times <- 1..99 do
      {:ok, _crachsubscriber} = Supervisor.start_child(sup_pid, [{topic, self()}])
    end

    {:ok, _subscriber} = Supervisor.start_child(callback_sup, [{topic, [], self()}])

    100 = length(Registry.lookup(Hobot.PubSub, topic))

    pid = self()
    ref = make_ref()
    data = "Hello world!"
    :ok = Hobot.PubSub.publish(topic, pid, ref, data)

    Process.sleep(10)

    assert length(Registry.lookup(Hobot.PubSub, topic)) < 100
  end
end
