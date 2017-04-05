defmodule Hobot.Publisher do
  @moduledoc """
  A publisher which publishes topics to `Hobot`
  """

  @doc "Publishes data to the topic"
  @callback do_publish(1, String.t, any) :: :ok

  defmacro __using__(_opts) do
    quote do
      @behaviour Hobot.Publisher

      @doc false
      def do_publish(1, topic, data) when is_binary(topic) do
        Hobot.publish(1, topic, data)
      end
    end
  end
end
