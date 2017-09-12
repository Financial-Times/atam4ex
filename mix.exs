defmodule ATAM4Ex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :atam4ex,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 3.1"},
      {:httpoison, "~> 0.12"},
      {:yaml_elixir, "~> 1.3"},
      {:plug, "~> 1.4"},
      {:cowboy, "~> 1.0.0"},
    ]
  end
end
