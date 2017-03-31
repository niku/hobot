defmodule Hobot.CLI do
  @moduledoc """
  This module contains functions to parse command line and dispatch to commands.
  """

  @doc """
  Starts a homunculus
  """
  @spec main(OptionParser.argv) :: no_return()
  def main(argv) do
    parsed_args = parse(argv)
    parsed_args
    |> dispatch
    |> call
  end

  @doc """
  Parses arguments
  """
  @spec parse(OptionParser.argv) :: keyword(boolean | String.t)
  def parse(argv) do
    {opts, _args, _errors} = OptionParser.parse(argv, [aliases: [g: :generate,
                                                                 h: :help,
                                                                 l: :load],
                                                       strict: [dotenv: :boolean,
                                                                generate: :boolean,
                                                                help: :boolean,
                                                                load: :string]])
    opts
  end

  @doc """
  Dispatches to a specific command
  """
  @spec dispatch(keyword(boolean | String.t)) :: {module, atom, [term]}
  def dispatch(opts) do
    keys = Keyword.keys(opts)
    cond do
      Enum.member?(keys, :help) -> {Hobot.Commands, :help, []}
      Enum.member?(keys, :generate) -> {Hobot.Commands, :generate, []}
      true -> {Hobot.Commands, :run, [opts]}
    end
  end

  @doc """
  Calls command which given a parameter
  """
  @spec call({module, atom, [term]}) :: any
  def call({mod, fun, args}), do: apply(mod, fun, args)
end
