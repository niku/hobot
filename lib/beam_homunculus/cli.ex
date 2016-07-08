defmodule BeamHomunculus.CLI do
  @moduledoc """
  This module contains functions to parse command line and dispatch to commands.
  """

  @doc """
  Starts a homunculus
  """
  @spec main(OptionParser.argv) :: no_return()
  def main(argv) do
    opts = parse(argv)
    dispatch(opts)
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
end
