defmodule MangaExCli.MixProject do
  use Mix.Project

  def project do
    [
      app: :manga_ex_cli,
      version: "0.1.0",
      elixir: "~> 1.10",
      config_path: "./configs/config.exs",
      escript: [main_module: MangaExCli.Cli],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {MangaExCli.Application, []},
      extra_applications: [
        :logger
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:manga_ex, "~> 0.5.0"},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:progress_bar, "> 0.0.0"},
      {:ratatouille, "~> 0.5.0"},
      {:ex_termbox, "1.0.2"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
