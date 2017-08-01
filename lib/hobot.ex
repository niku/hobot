defmodule Hobot do
  @moduledoc """
  A bot framework for ErlangVM(beam)
  """

  def create(name, adapter, handlers, options \\ []) do
    name_registry = Keyword.get(options, :name_registry, Hobot.Application.name_registry())
    pub_sub = Keyword.get(options, :pub_sub, Hobot.Application.pub_sub())
    task_supervisor = Keyword.get(options, :task_supervisor, Hobot.Application.task_supervisor())

    Supervisor.start_child(Hobot.Supervisor,
      [%{name: name,
         adapter: adapter,
         handlers: handlers,
         name_registry: name_registry,
         pub_sub: pub_sub,
         task_supervisor: task_supervisor}])
  end
end
