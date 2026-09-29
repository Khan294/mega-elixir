defmodule MegaElixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :mega_elixir,
      version: "0.1.0",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MegaElixir, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.8.0"},
      {:bandit, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:ecto_sql, "~> 3.13"},
      {:postgrex, "~> 0.21"}
    ]
  end
end
