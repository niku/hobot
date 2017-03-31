defmodule Hobot.Adapter do
  @moduledoc """
  A connection adapter between from the bot to an outer environment
  """

  @doc "Inputs stream from an outer environment"
  @callback input(Keyword.t(atom)) :: Enumerable.t

  @doc "Outputs message to an outer environmnent"
  @callback output(String.t) :: any

  defmacro __using__(opts) do
    quote do
      @behaviour Hobot.Adapter

      @doc false
      def do_input(config) do
        Stream.each(input(config), &Hobot.Bot.input/1)
      end

      @doc false
      def do_output(message) do
        Task.start(__MODULE__, :output, [message])
      end
    end
  end
end
