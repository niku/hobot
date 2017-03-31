defmodule Hobot.Mixfile do
  use Mix.Project

  def project do
    [app: :hobot,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps(),
     dialyzer: dialyzer(),
     escript: [main_module: Hobot.CLI]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger],
     mod: {Hobot.Application, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:ex_doc, ">= 0.0.0", only: [:dev, :test]},
     {:dialyxir, "~> 0.3.5", only: [:dev, :test]},
     {:credo, "~> 0.4", only: [:dev, :test]}]
  end

  defp description do
    "A bot framework for ErlangVM(beam)"
  end

  defp package do
    [maintainers: ["niku"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/niku/hobot"}]
  end

  defp dialyzer do
    if System.get_env("TRAVIS") do
      [plt_file: Path.join("plt", ".dialyxir_core_#{:erlang.system_info(:otp_release)}_#{System.version()}.plt")]
    else
      []
    end
  end
end
