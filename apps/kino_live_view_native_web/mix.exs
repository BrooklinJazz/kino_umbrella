defmodule KinoLiveViewNativeWeb.MixProject do
  use Mix.Project

  def project do
    [
      app: :kino_live_view_native_web,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {KinoLiveViewNativeWeb.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.11"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.14", override: true},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:kino_live_view_native, in_umbrella: true},
      {:jason, "~> 1.2"},
      {:bandit, "~> 1.2"},
      {:live_view_native, github: "liveview-native/live_view_native", branch: "main", override: true},
      {:live_view_native_swiftui, github: "liveview-native/liveview-client-swiftui", tag: "0.3.0-alpha.4"},
      {:live_view_native_jetpack, github: "liveview-native/liveview-client-jetpack", tag: "0.3.0-alpha.3"},
      {:live_view_native_html, github: "liveview-native/live_view_native_html", tag: "0.3.0-alpha.3"},
      {:live_view_native_stylesheet, github: "liveview-native/live_view_native_stylesheet", branch: "main", override: true},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind kino_live_view_native_web", "esbuild kino_live_view_native_web"],
      "assets.deploy": [
        "tailwind kino_live_view_native_web --minify",
        "esbuild kino_live_view_native_web --minify",
        "phx.digest"
      ]
    ]
  end
end
