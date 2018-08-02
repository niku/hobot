defmodule Hobot.MixProject do
  use Mix.Project

  def project do
    [
      app: :hobot,
      version: "0.3.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Hobot.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.19-rc", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: :dev, runtime: false},
      {:credo, "~> 0.10.0", only: :dev, runtime: false}
    ]
  end

  defp description do
    "A bot framework for ErlangVM(beam)"
  end

  defp package do
    [
      maintainers: ["niku"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/niku/hobot"
      }
    ]
  end
end
