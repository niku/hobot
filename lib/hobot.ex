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

    handlers_with_index = Enum.with_index(handlers)
    Supervisor.start_child(Hobot.Supervisor,
      [%{name: name,
         adapter: adapter,
         handlers: handlers_with_index,
         application_process: application_process}])
  end

  def context(value, name_registry \\ Hobot.Application.name_registry())

  def context(name, name_registry) when is_binary(name) do
    Agent.get({:via, Registry, {name_registry, Hobot.Bot.context(name)}}, &(&1))
  catch
    :exit, _ ->
      nil
  end

  def context(pid, _name_registry) when is_pid(pid) do
    children = Supervisor.which_children(pid)
    case Enum.find(children, fn {process_name, _, _, _} ->  Regex.match?(~r"Context", process_name) end) do
      {context_process_name, _, _, _} ->
        Agent.get({:via, Registry, {Hobot.Application.name_registry(), context_process_name}}, &(&1))
      _ ->
        nil
    end
  end
end
