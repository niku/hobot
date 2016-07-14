defmodule BeamHomunculus.Bot do
  @moduledoc """
  A bot server
  """

  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end
end
