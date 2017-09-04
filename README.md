# Hobot(an abbreviation of Homunculus Bot)

[![Build Status](https://travis-ci.org/niku/hobot.svg?branch=master)](https://travis-ci.org/niku/hobot)

A bot framework for Erlang VM(BEAM). Plugins for Hobot are just :gen_server so you can meke a plugin with any language on the Erlang VM.

You can see [an adapter sample](https://github.com/niku/hobot/tree/v0.2.0/lib/hobot/adapters/shell.ex) and [a handler sample](https://github.com/niku/hobot/tree/v0.2.0/lib/hobot/handlers/echo.ex).

## Usage

```console
% git clone https://github.com/niku/hobot
% cd hobot
% mix deps.get
% iex -S mix
Erlang/OTP 20 [erts-9.0] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Interactive Elixir (1.5.1) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> bot_name = "EchoBot"
iex(2)> adapter_conf = %{module: Hobot.Plugin.Adapter.Shell, args: [Process.group_leader()]}
iex(3)> handlers_conf = [%{module: Hobot.Handlers.Echo, args: [["on_message"]]}]
iex(4)> {:ok, echo_bot} = Hobot.create(bot_name, adapter_conf, handlers_conf)
iex(5)> context = Hobot.context(echo_bot)
iex(6)> adapter_pid = Hobot.pid(context.adapter)
iex(7)> Hobot.Plugin.Adapter.Shell.gets("> ", adapter_pid)
> hello
"hello"
> hi
"hi"
> quit
nil
iex(8)>
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `hobot` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:hobot, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/hobot](https://hexdocs.pm/hobot).
