defmodule UeberauthMollie.MixProject do
  use Mix.Project

  @source_url "https://github.com/wearethefoos/ueberauth_mollie"
  @version "1.0.0"

  def project do
    [
      app: :ueberauth_mollie,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: dialyzer(),
      docs: docs(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ueberauth, :oauth2]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:oauth2, "~> 1.0 or ~> 2.0"},
      {:ueberauth, "~> 0.10"},
      {:tesla, "~> 1.4"},
      {:hackney, "~> 1.17"},
      {:jason, ">= 1.0.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4.1", only: [:dev], runtime: false},
      {:mock, "~> 0.3", only: :test}
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md": [title: "Changelog"],
        "CONTRIBUTING.md": [title: "Contributing"],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  defp package do
    [
      description: "An Ueberauth strategy for using Mollie to authenticate your users.",
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["Wouter de Vos"],
      licenses: ["MIT"],
      links: %{
        Changelog: "https://hexdocs.pm/ueberauth_mollie/changelog.html",
        GitHub: @source_url
      }
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "lint.setup"],
      "lint.setup": ["dialyzer --plt"],
      lint: [
        "format --check-formatted",
        "credo --strict",
        "dialyzer --no-check"
      ]
    ]
  end

  defp dialyzer do
    [
      plt_core_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end
end
