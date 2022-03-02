defmodule Laingen.MixProject do
  use Mix.Project

  def project do
    [
      app: :laingen,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:yaml_front_matter],
      extra_applications: [:logger, :solid, :earmark]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:solid, "~> 0.10"},
      {:yaml_front_matter, "~> 1.0.0"},
      {:earmark, "~> 1.4"}
    ]
  end
end
