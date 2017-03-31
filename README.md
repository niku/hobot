# Hobot(an abbreviation of Homunculus Bot)

[![Build Status](https://travis-ci.org/niku/hobot.svg?branch=master)](https://travis-ci.org/niku/hobot)

A bot framework for ErlangVM(beam)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `hobot` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:hobot, "~> 0.1.0"}]
    end
    ```

  2. Ensure `hobot` is started before your application:

    ```elixir
    def application do
      [applications: [:hobot]]
    end
    ```

If [published on Hexdocs](https://hex.pm/docs/tasks#hex_docs), the docs can
be found at [https://hexdocs.pm/hobot](https://hexdocs.pm/hobot)
