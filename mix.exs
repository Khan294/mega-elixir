defmodule MegaElixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :mega_elixir,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {MegaElixir.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:phoenix, "~> 1.8.0"},
      {:plug_cowboy, "~> 2.7"}
    ]
  end
end
