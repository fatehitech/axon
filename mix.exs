defmodule Axon.Mixfile do
  use Mix.Project

  def project do
    [app: :axon,
     version: "0.0.1",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger,:firmata, :serial],
     mod: {Axon, []}]
  end

  defp deps do
    [
      {:firmata, path: "/Users/keyvan/Workspace/firmata"},
      {:serial, path: "/Users/keyvan/Workspace/elixir_serial"},
      {:credo, "~> 0.2", only: [:dev, :test]},
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev}
    ]
  end
end
