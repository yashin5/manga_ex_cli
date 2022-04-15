defmodule MangaExCli.Helpers do
  import Ratatouille.View

  def pages(%{pages: pages, actual_page: actual_page}) do
    label do
      if pages == actual_page do
        text(
          background: :white,
          color: :black,
          content: "... Page #{pages} "
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

      if pages != actual_page do
        text(content: " ... Page #{pages}")
      end
    end
  end

  def render_welcome_message do
    cols =
      "cols"
      |> num()
      |> Kernel./(2)
      |> Float.floor()
      |> trunc()

    message = String.pad_leading("Welcome to MangaEx!", cols)

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
