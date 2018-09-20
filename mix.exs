defmodule Indacoin.MixProject do
  use Mix.Project

  def project do
    [
      app: :indacoin,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 1.3"},
      {:poison, "~> 4.0"},
      {:junit_formatter, "~> 2.2", only: :test},
      {:excoveralls, "~> 0.10", only: :test}
    ]
  end
end
