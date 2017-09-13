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
      extra_applications: [:logger, :ex_unit]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:yaml_elixir, "~> 1.3", optional: true},
      {:poison, "~> 3.1", optional: true},
      {:plug, "~> 1.4", optional: true},
      {:cowboy, "~> 1.0", optional: true},
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:distillery, ">= 0.8.0", warn_missing: false}
    ]
  end
end
