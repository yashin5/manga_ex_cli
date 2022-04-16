defmodule MangaExCli.Application do
  use Application

  def start(_type, _args) do
    children = [MangaExCli.PercentageMonitor, MangaExCli.RowsMonitor]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
