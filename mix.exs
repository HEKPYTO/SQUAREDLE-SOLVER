defmodule SquaredleSolver.MixProject do
  use Mix.Project

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def project do
    [
      app: :squaredle_solver,
      version: "0.1.0",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      listeners: [Phoenix.CodeReloader],
      test_coverage: [
        tool: ExCoveralls,
        ignore_modules: [
          SquaredleSolverWeb.CoreComponents,
          SquaredleSolverWeb.Gettext,
          SquaredleSolverWeb.Layouts,
          SquaredleSolverWeb.ErrorHTML,
          SquaredleSolverWeb.ErrorJSON,
          SquaredleSolverWeb.Telemetry
        ]
      ]
    ]
  end

  def application do
    [
      mod: {SquaredleSolver.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.8.4"},
      {:phoenix_html, "~> 4.3"},
      {:phoenix_live_reload, "~> 1.6", only: :dev},
      {:phoenix_live_view, "~> 1.0.0", override: true},
      {:floki, ">= 0.30.0", only: :test},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.4", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},
      {:excoveralls, "~> 0.18", only: :test},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind squaredle_solver", "esbuild squaredle_solver"],
      "assets.deploy": [
        "tailwind squaredle_solver --minify",
        "esbuild squaredle_solver --minify",
        "phx.digest"
      ]
    ]
  end
end
