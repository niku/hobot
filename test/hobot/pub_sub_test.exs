defmodule Hobot.PubSubTest do
  use ExUnit.Case, async: true
  doctest Hobot.PubSub

  @moduletag :capture_log

  defmodule CallbackSubscriber do
    use GenServer

    def start_link(args, opts \\ []) do
      GenServer.start_link(__MODULE__, args, opts)
    end

    def init({registry, name, topic, before_receive, _callback_pid} = args) do
      Hobot.PubSub.subscribe(registry, name, topic, before_receive)
      {:ok, args}
    end

    def handle_cast({:broadcast, topic, ref, data}, {_registry, _name, _toipc, _before_receive, callback_pid} = state) do
      send(callback_pid, {:broadcast, topic, ref, data})
      {:noreply, state}
    end
  end

  defmodule CrashSubscriber do
    use GenServer, restart: :temporary

    def start_link(args, opts \\ []) do
      GenServer.start_link(__MODULE__, args, opts)
    end

    def init({registry, name, topic, before_receive, callback_pid}) do
      Hobot.PubSub.subscribe(registry, name, topic, before_receive)
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

    def start_link(args, opts \\ []) do
      GenServer.start_link(__MODULE__, args, opts)
    end

    def init({registry, name, topic, before_receive, _callback_pid}) do
      Hobot.PubSub.subscribe(registry, name, topic, before_receive)
      {:ok, []}
    end

    def handle_cast(_message, state) do
      Process.sleep(1000)
      {:noreply, state}
    end
  end

  setup context do
    # It needs an atom which points a pid for the first argument of Registry functions.
    pub_sub = Module.concat([__MODULE__, "PubSubRegistry", context.test])
    {:ok, _} = Registry.start_link(keys: :duplicate, name: pub_sub)

    # It needs an atom which points a pid for the first argument of Task.Supervisor.start_child/2.
    task_supervisor = Module.concat([__MODULE__, "TaskSupervisor", context.test])
    {:ok, _} = Supervisor.start_link([{Task.Supervisor, name: task_supervisor}], strategy: :one_for_one)

    {:ok, callback_sup} = Supervisor.start_link([
      Supervisor.child_spec(CallbackSubscriber, start: {CallbackSubscriber, :start_link, []})
    ], strategy: :simple_one_for_one)
    {:ok, crash_sup} = Supervisor.start_link([
      Supervisor.child_spec(CrashSubscriber, start: {CrashSubscriber, :start_link, []})
    ], strategy: :simple_one_for_one)
    {:ok, slow_sup} = Supervisor.start_link([
      Supervisor.child_spec(SlowSubscriber, start: {SlowSubscriber, :start_link, []})
    ], strategy: :simple_one_for_one)

    {:ok, [pub_sub: pub_sub, task_supervisor: task_supervisor, callback_sup: callback_sup, crash_sup: crash_sup, slow_sup: slow_sup]}
  end

  test "A subscriber receives a message which is published", %{pub_sub: pub_sub, task_supervisor: task_supervisor, callback_sup: callback_sup} do
    name = "Foo"
    topic = "foo"
    before_receive = []
    callback_pid = self()
    {:ok, _subscriber} = Supervisor.start_child(callback_sup, [{pub_sub, name, topic, before_receive, callback_pid}])

    ref = make_ref()
    data = "Hello world!"
    before_publish = []
    {:ok, _pid}  = Hobot.PubSub.publish(pub_sub, name, topic, ref, data, task_supervisor, before_publish)
    assert_receive {:broadcast, ^topic, ^ref, ^data}
  end

  test "A subscriber receives no message when it haven't subscribe the topic which is published", %{pub_sub: pub_sub, task_supervisor: task_supervisor, callback_sup: callback_sup} do
    name = "Foo"
    topic = "foo"
    no_subscribed_topic = "bar"
    before_receive = []
    callback_pid = self()
    {:ok, _subscriber} = Supervisor.start_child(callback_sup, [{pub_sub, name, topic, before_receive, callback_pid}])

    ref = make_ref()
    data = "Hello world!"
    before_publish = []
    {:ok, _pid}  = Hobot.PubSub.publish(pub_sub, name, no_subscribed_topic, ref, data, task_supervisor, before_publish)
    refute_receive _anything
  end

  test "A subscriber receives a message even if other subscribers crashed", %{pub_sub: pub_sub, task_supervisor: task_supervisor, callback_sup: callback_sup, crash_sup: crash_sup} do
    name = "Foo"
    topic = "foo"
    before_receive = []
    callback_pid = self()

    {:ok, crashsubscriber} = Supervisor.start_child(crash_sup, [{pub_sub, name, topic, before_receive, callback_pid}])
    {:ok, _subscriber} = Supervisor.start_child(callback_sup, [{pub_sub, name, topic, before_receive, callback_pid}])

    ref = make_ref()
    data = "Hello world!"
    before_publish = []
    {:ok, _pid}  = Hobot.PubSub.publish(pub_sub, name, topic, ref, data, task_supervisor, before_publish)
    assert_receive {:broadcast, ^topic, ^ref, ^data}

    receive do
      "terminated" ->
        # Waiting for the process crashed completely
        Process.sleep(10)
        false = Process.alive?(crashsubscriber) # assume the process is not alive.
    end

    data = "Hello world again!"
    {:ok, _pid}  = Hobot.PubSub.publish(pub_sub, name, topic, ref, data, task_supervisor, before_publish)
    assert_receive {:broadcast, ^topic, ^ref, ^data}
  end

  test "A subscriber receives message with low latency even if other subscribers are slow", %{pub_sub: pub_sub, task_supervisor: task_supervisor, callback_sup: callback_sup, slow_sup: slow_sup} do
    name = "Foo"
    topic = "foo"
    before_receive = []
    callback_pid = self()

    # Make a hundred of slow subscribers
    for _times <- 0..99 do
      {:ok, _slow_subscriber} = Supervisor.start_child(slow_sup, [{pub_sub, name, topic, before_receive, callback_pid}])
    end
    {:ok, _callback_subscriber} = Supervisor.start_child(callback_sup, [{pub_sub, name, topic, before_receive, callback_pid}])

    for _times <- 0..2 do
      ref = make_ref()
      data = "Hello world!"
      before_publish = []
      {:ok, _pid}  = Hobot.PubSub.publish(pub_sub, name, topic, ref, data, task_supervisor, before_publish)
      assert_receive {:broadcast, ^topic, ^ref, ^data}, 10 # timeout 10ms
    end
  end

  test "The broker eliminates crashed subscriber from own registry", %{pub_sub: pub_sub, task_supervisor: task_supervisor, callback_sup: callback_sup}  do
    # See also
    # https://hexdocs.pm/elixir/1.5.1/Registry.html#module-registrations

    name = "Foo"
    topic = "foo"
    before_receive = []
    callback_pid = self()

    {:ok, sup_pid} = Supervisor.start_link([
      # Note: `restart: :temporary`
      Supervisor.child_spec(CrashSubscriber, start: {CrashSubscriber, :start_link, []})
    ], strategy: :simple_one_for_one)
    for _times <- 0..99 do
      {:ok, _crachsubscriber} = Supervisor.start_child(sup_pid, [{pub_sub, name, topic, before_receive, callback_pid}])
    end
    {:ok, _subscriber} = Supervisor.start_child(callback_sup, [{pub_sub, name, topic, before_receive, callback_pid}])

    # 0..99 -> crachsubscriber 100 elements
    #        + subscriber 1 element
    #        = 101 elements
    101 = length(Registry.lookup(pub_sub, {name, topic}))

    ref = make_ref()
    data = "Hello world!"
    before_publish = []
    {:ok, _pid}  = Hobot.PubSub.publish(pub_sub, name, topic, ref, data, task_supervisor, before_publish)

    # Waiting for terminating processes
    Process.sleep(10)

    assert length(Registry.lookup(pub_sub, {name, topic})) == 1
  end
end
