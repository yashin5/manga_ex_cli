defmodule MangaExCli.PercentageMonitor do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
  end

  def get_actual_percentage do
    Agent.get(__MODULE__, & &1)
  end

  def update_percentage(actual_percentage) do
    Agent.update(__MODULE__, fn _ -> actual_percentage end)
  end
end
