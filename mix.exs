defmodule ATAM4Ex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :atam4ex,
      version: "1.0.0",
      elixir: "~> 1.8",
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
      {:yaml_elixir, "~> 2.4", optional: true},
      {:jason, "~> 1.0", optional: true},
      {:plug_cowboy, "~> 2.0", optional: true},
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:distillery, ">= 0.8.0", warn_missing: false}
    ]
  end
end
