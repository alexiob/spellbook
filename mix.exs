defmodule Spellbook.Mixfile do
  use Mix.Project

  def project do
    [
      app: :spellbook,
      version: "1.0.1",
      name: "Spellbook",
      source_url: "https://github.com/alexiob/spellbook",
      homepage_url: "https://github.com/alexiob/spellbook",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      elixirc_paths: paths(Mix.env),
      description: description(),
      package: package(),
      deps: deps(),
      docs: [
        extras: ["README.md"]
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "coveralls": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [applications: applications(Mix.env)]
  end

  defp deps do
    [
      {:credo, "~> 0.4", only: [:dev]},
      {:dialyze, "~> 0.2", only: [:dev]},
      {:dialyxir, "~> 0.3", only: [:dev]},
      {:mr_t, "~> 0.6.0", only: [:test, :dev]}, # instant code-reloader and test runner
      {:ex_doc, "~> 0.13", only: [:dev, :docs]},
      {:ex_doc_dash, "~> 0.2", only: :docs},
      {:inch_ex, ">= 0.0.0", only: :docs},
      {:excoveralls, "~> 0.5", only: :test},

      {:poison, "~> 2.2"}, # pure Elixir JSON library

      {:yamerl, "~> 0.3"}, # Erlang YAML parser
      {:yaml_elixir, "~> 1.2"}, # Elixir YAML parser

      {:dot_notes, "~> 1.0"}, # dot.notation
    ]
  end

  defp paths(:test) do
    ["lib", "test/support"]
  end
  defp paths(_) do
    ["lib"]
  end

  defp applications(env) when env in [:dev, :test] do
    [:logger, :yaml_elixir]
  end
  defp applications(_) do
    [:logger, :yaml_elixir]
  end

  defp description do
    """
    Provides dynamic hierarchical configurations loading from config files and
    environment variables.
    """
  end

  # https://hex.pm/docs/publish
  defp package do
    [
      name: :spellbook,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Alessandro Iob <alessandro.iob@gmail.com>"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/alexiob/spellbook"
      }
    ]
  end
end
