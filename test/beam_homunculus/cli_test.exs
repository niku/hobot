defmodule BeamHomunculus.CLITest do
  use ExUnit.Case, async: true

  describe "BeamHomunculus.CLI.parse/1" do
    test ~s(given "--dotenv") do
      assert BeamHomunculus.CLI.parse(~w(--dotenv)) == [dotenv: true]
    end

    test ~s(given "--help") do
      assert BeamHomunculus.CLI.parse(~w(--help)) == [help: true]
    end

    test ~s(given "-h") do
      assert BeamHomunculus.CLI.parse(~w(-h)) == [help: true]
    end

    test ~s(given "--generate") do
      assert BeamHomunculus.CLI.parse(~w(--generate)) == [generate: true]
    end

    test ~s(given "-g") do
      assert BeamHomunculus.CLI.parse(~w(-g)) == [generate: true]
    end

    test ~s(given "--load foo/bar.exs") do
      assert BeamHomunculus.CLI.parse(~w(--load foo/bar.exs)) == [load: "foo/bar.exs"]
    end

    test ~s(given "-l foo/bar.exs") do
      assert BeamHomunculus.CLI.parse(~w(-l foo/bar.exs)) == [load: "foo/bar.exs"]
    end

    test "given no arguments" do
      assert BeamHomunculus.CLI.parse(~w()) == []
    end

    test ~s(given "--help --generate -l foo/bar.exs") do
      assert BeamHomunculus.CLI.parse(~w(--help --generate -l foo/bar.exs)) == [help: true, generate: true, load: "foo/bar.exs"]
    end
  end

  describe "BeamHomunculus.CLI.dispatch/1" do
    test "given [help: true]" do
      assert BeamHomunculus.CLI.dispatch([help: true]) == {BeamHomunculus.Commands, :help, []}
    end

    test "given [generate: true]" do
      assert BeamHomunculus.CLI.dispatch([generate: true]) == {BeamHomunculus.Commands, :generate, []}
    end

    test "given []" do
      assert BeamHomunculus.CLI.dispatch([]) == {BeamHomunculus.Commands, :run, [[]]}
    end

    test ~s(given [dotenv: true, load: "foo/bar.exs"]) do
      assert BeamHomunculus.CLI.dispatch([dotenv: true, load: "foo/bar.exs"]) == {BeamHomunculus.Commands, :run, [[dotenv: true, load: "foo/bar.exs"]]}
    end

    test "given [dotenv: true, generate: true, help: true]" do
      assert BeamHomunculus.CLI.dispatch([generate: true, help: true]) == {BeamHomunculus.Commands, :help, []}
    end
  end
end
