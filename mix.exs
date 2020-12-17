defmodule ATAM4Ex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :atam4ex,
      version: "1.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ex_unit]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:yaml_elixir, "~> 2.5", optional: true},
      {:jason, "~> 1.2", optional: true},
      {:plug, "~> 1.11"},
      {:plug_cowboy, "~> 2.4", optional: true},
      {:credo, "~> 1.5", only: [:dev, :test]},
      {:ex_doc, "~> 0.23.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end
end
