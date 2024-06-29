defmodule VortexPubSub.MixProject do
  use Mix.Project

  def project do
    [
      app: :vortex_pub_sub,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {VortexPubSub, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:plug_cowboy, "~> 2.7"},
      {:phoenix_pubsub, "~> 2.1"},
      {:ecto_sql, "~> 3.11"},
      {:ecto_enum, "~> 1.4"},
      {:jason, "~> 1.4"},
      {:joken, "~> 2.6"},
      {:elixir_uuid, "~> 1.2"},
      {:finch, "~> 0.18.0"},
      {:postgrex, "~> 0.18.0"},
      {:credo, "~> 1.7"},
      {:timex, "~> 3.7"},
      {:websockex, "~> 0.4.3", only: :test},
      {:kafka_ex, "~> 0.13.0"},
      {:mongodb_ecto, "~> 1.1.2"}

    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/_support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
