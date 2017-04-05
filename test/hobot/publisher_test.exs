defmodule Hobot.PublisherTest do
  use ExUnit.Case, async: true

  defmodule TestPublisher do
    use Hobot.Publisher

    def publish(topic, data) do
      do_publish(1, topic, data)
    end
  end

  describe "Publisher.publish/3" do
    test "first argument is binary" do
      assert TestPublisher.publish("foo", [1,2,3]) == :ok
    end

    test "first argument is not binary" do
      assert_raise FunctionClauseError, fn ->
        TestPublisher.publish('foo', [1,2,3])
      end
    end
  end
end
