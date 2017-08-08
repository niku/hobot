defmodule Hobot.ApplicationProcess do
  @moduledoc """
  Processes associated with the Application
  """

  @processes [:name_registry, :pub_sub, :task_supervisor]
  @enforce_keys @processes
  defstruct @processes
end
