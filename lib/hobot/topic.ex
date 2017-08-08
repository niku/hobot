defmodule Hobot.Topic do
  @moduledoc """
  A topic in a bot
  """

  @keys [:bot_name, :value]
  @enforce_keys @keys
  defstruct @keys
end
