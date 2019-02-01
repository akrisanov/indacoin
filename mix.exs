defmodule Indacoin.MixProject do
  use Mix.Project

  @description """
    An Elixir interface to the Indacoin API
  """

  def project do
    [
      app: :indacoin,
      version: "1.0.2",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      name: "Indacoin",
      description: @description,
      package: package(),
      deps: deps(),
      source_url: "https://github.com/akrisanov/indacoin",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      env: [api_host: "https://indacoin.com/"]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support/"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:httpoison, "~> 1.3"},
      {:jason, "~> 1.1"},
      {:earmark, "~> 1.2", only: :dev},
      {:ex_doc, "~> 0.19.1", only: :dev},
      {:bypass, "~> 0.8", only: :test},
      {:junit_formatter, "~> 2.2", only: :test},
      {:excoveralls, "~> 0.10", only: :test}
    ]
  end

  defp package do
    [
      maintainers: ["Andrey Krisanov"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "https://github.com/akrisanov/indacoin/blob/master/CHANGELOG.md",
        "GitHub" => "https://github.com/akrisanov/indacoin"
      }
    ]
  end
end
