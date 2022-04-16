defmodule MangaExCli.RowsMonitor do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> 32 end, name: __MODULE__)
  end

  def get_rows_to_use do
    Agent.get(__MODULE__, fn
      actual_value when actual_value <= 32 ->
        3

      actual_value ->
        actual_value - 32 + 2
    end)
  end

  def update_rows do
    Agent.update(__MODULE__, fn _ -> elem(:io.rows(), 1) end)
  end
end
