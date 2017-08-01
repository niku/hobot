defmodule Hobot.Application do
  @moduledoc false

  use Application

  @name_registry Hobot.NameRegistry
  @pub_sub Hobot.PubSub
  @task_supervisor Hobot.TaskSupervisor

  def start(_type, _args) do
    children = [
      %{
        start: {Registry, :start_link, [[keys: :unique, name: @name_registry, partitions: System.schedulers_online()]]},
        id: @name_registry,
      },
      %{
        start: {Registry, :start_link, [[keys: :duplicate, name: @pub_sub, partitions: System.schedulers_online()]]},
        id: @pub_sub,
      },
      {Task.Supervisor, name:  @task_supervisor},
      {Hobot.Supervisor, name_registry: @name_registry, task_supervisor: @task_supervisor}
    ]

    opts = [strategy: :one_for_one, name: Hobot.ApplicationSupervisor]
    Supervisor.start_link(children, opts)
  end

  def name_registry, do: @name_registry
  def pub_sub, do: @pub_sub
  def task_supervisor, do: @task_supervisor
end
