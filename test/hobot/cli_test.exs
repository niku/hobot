defmodule Hobot.CLITest do
  use ExUnit.Case, async: true

  describe "Hobot.CLI.parse/1" do
    test ~s(given "--dotenv") do
      assert Hobot.CLI.parse(~w(--dotenv)) == [dotenv: true]
    end

    test ~s(given "--help") do
      assert Hobot.CLI.parse(~w(--help)) == [help: true]
    end

    test ~s(given "-h") do
      assert Hobot.CLI.parse(~w(-h)) == [help: true]
    end

    test ~s(given "--generate") do
      assert Hobot.CLI.parse(~w(--generate)) == [generate: true]
    end

    test ~s(given "-g") do
      assert Hobot.CLI.parse(~w(-g)) == [generate: true]
    end

    test ~s(given "--load foo/bar.exs") do
      assert Hobot.CLI.parse(~w(--load foo/bar.exs)) == [load: "foo/bar.exs"]
    end

    test ~s(given "-l foo/bar.exs") do
      assert Hobot.CLI.parse(~w(-l foo/bar.exs)) == [load: "foo/bar.exs"]
    end

    test "given no arguments" do
      assert Hobot.CLI.parse(~w()) == []
    end

    test ~s(given "--help --generate -l foo/bar.exs") do
      assert Hobot.CLI.parse(~w(--help --generate -l foo/bar.exs)) == [help: true, generate: true, load: "foo/bar.exs"]
    end
  end

  describe "Hobot.CLI.dispatch/1" do
    test "given [help: true]" do
      assert Hobot.CLI.dispatch([help: true]) == {Hobot.Commands, :help, []}
    end

    test "given [generate: true]" do
      assert Hobot.CLI.dispatch([generate: true]) == {Hobot.Commands, :generate, []}
    end

    test "given []" do
      assert Hobot.CLI.dispatch([]) == {Hobot.Commands, :run, [[]]}
    end

    test ~s(given [dotenv: true, load: "foo/bar.exs"]) do
      assert Hobot.CLI.dispatch([dotenv: true, load: "foo/bar.exs"]) == {Hobot.Commands, :run, [[dotenv: true, load: "foo/bar.exs"]]}
    end

    test "given [dotenv: true, generate: true, help: true]" do
      assert Hobot.CLI.dispatch([generate: true, help: true]) == {Hobot.Commands, :help, []}
    end
  end
end
