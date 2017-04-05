defmodule Hobot.SubscriberTest do
  use ExUnit.Case

  @moduletag :capture_log

  defmodule TestSubscriber do
    use Hobot.Subscriber

    def do_handle(topic, data, pid_state) do
      send(pid_state, {topic, data})
    end
  end

  setup do
    Application.stop(:hobot)
    :ok = Application.start(:hobot)
  end

  test "Receive data about subscribed topic" do
    topic = "foo"
    data = "Hello world!"
    TestSubscriber.start_link(topic, self())
    Hobot.publish(1, topic, data)
    assert_receive {^topic, ^data}
  end

  test "No receive data about no subscribed topic" do
    topic = "foo"
    data = "Hello world!"
    TestSubscriber.start_link(topic, self())
    Hobot.publish(1, "bar", data)
    refute_receive _
  end

  test "Subscribe multiple topics on start" do
    topics = ["foo", "bar"]
    data = "Hello world!"
    TestSubscriber.start_link(topics, self())

    for topic <- topics do
      Hobot.publish(1, topic, data)
      assert_receive {^topic, ^data}
    end

    Hobot.publish(1, "baz", "do not receive it")
    refute_receive _
  end
end
