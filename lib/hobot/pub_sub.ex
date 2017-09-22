defmodule Hobot.PubSub do
  @moduledoc """
  Functions that work on Registry to use a PubSub in Hobot application.
  """

  def subscribe(%Hobot.ApplicationProcess{} = application_process, %Hobot.Topic{} = topic, before_receive) do
    Registry.register(application_process.pub_sub, topic, before_receive)
  end

  def unsubscribe(%Hobot.ApplicationProcess{} = application_process, %Hobot.Topic{} = topic) do
    Registry.unregister(application_process.pub_sub, topic)
  end

  def publish(%Hobot.ApplicationProcess{} = application_process, %Hobot.Topic{} = topic, ref, data, before_publish) do
    message = {:broadcast, topic.value, ref, data}
    Task.Supervisor.start_child(application_process.task_supervisor, fn ->
      case Hobot.Middleware.apply_middleware(before_publish, message) do
        {:ok, value} ->
          dispatch(application_process, topic, value)
        {:halt, value} ->
          application_process.logger.debug("halted at before publish. reason: #{inspect value}")
      end
    end)
  end

  @doc false
  def dispatch(application_process, topic, message) do
    Registry.dispatch(application_process.pub_sub, topic, fn entries ->
      for {pid, before_receive} <- entries do
        cast_to_process(application_process, pid, message, before_receive)
      end
    end)
  end

  @doc false
  def cast_to_process(application_process, pid, message, before_receive) do
    Task.Supervisor.start_child(application_process.task_supervisor, fn ->
      case Hobot.Middleware.apply_middleware(before_receive, message) do
        {:ok, value} ->
          GenServer.cast(pid, value)
        {:halt, value} ->
          application_process.logger.debug("halted at before receive. reason: #{inspect value}")
      end
    end)
  end
end
