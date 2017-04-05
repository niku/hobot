defmodule Hobot.Subscriber do
  @moduledoc """
  A subscriber which subscribes topics from `Hobot`
  """

  @doc "Handles data which is published from the broker"
  @callback do_handle(String.t, any, any) :: any

  defmacro __using__(_opts) do
    quote do
      @behaviour Hobot.Subscriber

      use GenServer

      @doc false
      def do_subscribe(topic), do: Hobot.subscribe(1, topic)

      @doc false
      def do_handle(topic, data, state) do
        # just ingnore data as default
      end

      def start_link(topic, state \\ [])
      def start_link(a_topic, state) when is_binary(a_topic), do: start_link([a_topic], state)
      def start_link(topics, state) when is_list(topics) do
        GenServer.start_link(__MODULE__, {topics, state}, name: __MODULE__)
      end

      def init({topics, state}) when is_list(topics) do
        for topic <- topics, do: do_subscribe(topic)
        {:ok, {topics, state}}
      end

      def handle_cast({:broadcast, topic, data}, {subscribed_topics, state}) do
        do_handle(topic, data, state)
        {:noreply, {subscribed_topics, state}}
      end

      defoverridable [do_handle: 3]
    end
  end
end
