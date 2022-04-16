defmodule MangaExCli.Helpers do
  import Ratatouille.View

  alias MangaExCli.RowsMonitor

  def filter_by_typed_text(text, elems_to_filter) do
    elems_to_filter
    |> Enum.filter(&String.contains?(&1, String.downcase(text)))
    |> Enum.map(fn provider ->
      color = if text == "", do: :white, else: :yellow
      label(color: color, content: provider)
    end)
  end

  def chunk_by_type(%{actual_page: actual_page, pages: pages}, elems_to_chunk, func_to_map) do
    actual_page_to_use = if actual_page > pages, do: pages, else: actual_page

    elems_to_chunk
    |> Enum.map(&func_to_map.(&1))
    |> Enum.chunk_every(RowsMonitor.get_rows_to_use())
    |> Enum.at(actual_page_to_use - 1)
  end

  def pages(%{pages: pages, actual_page: actual_page}) do
    label do
      if pages == actual_page and pages != 1 do
        text(
          background: :white,
          color: :black,
          content: "... Page #{pages} "
        )
      else
        if pages == 1 do
          text(
            background: :white,
            color: :black,
            content: " Page 1 "
          )
        else
          for page <- 1..pages do
            if page == actual_page do
              text(
                background: :white,
                color: :black,
                content: " Page #{page} "
              )
            end
          end
        end
      end

      if pages != actual_page and pages != 1 do
        text(content: " ... Page #{pages}")
      end
    end
  end

  def render_welcome_message do
    {:ok, cols} = :io.columns()

    message = String.pad_leading("Welcome to MangaEx!", div(cols, 2))

    row do
      column size: 12 do
        panel do
          label(color: :white, content: "#{message}")
        end
      end
    end
  end

  def num(subcommand) do
    case System.cmd("tput", [subcommand]) do
      {text, 0} ->
        text
        |> String.trim()
        |> String.to_integer()

      _ ->
        0
    end
  end

  def render_error(model) do
    row do
      column size: 12 do
        label(background: :red, content: model.error)
      end
    end
  end
end
