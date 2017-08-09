defmodule Hobot do
  @moduledoc """
  A bot framework for ErlangVM(beam)
  """

  def create(name, adapter, handlers, options \\ []) do
    application_process = %Hobot.ApplicationProcess{
      logger: Keyword.get(options, :logger, Logger),
      name_registry: Keyword.get(options, :name_registry, Hobot.Application.name_registry()),
      pub_sub: Keyword.get(options, :pub_sub, Hobot.Application.pub_sub()),
      task_supervisor: Keyword.get(options, :task_supervisor, Hobot.Application.task_supervisor())
    }

    Supervisor.start_child(Hobot.Supervisor,
      [%{name: name,
         adapter: adapter,
         handlers: handlers,
         application_process: application_process}])
  end
end
