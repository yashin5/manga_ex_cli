defmodule MangaExCli.Views.DownloadingChapters do
  import Ratatouille.View

  alias MangaExCli.Helpers

  def render(%{downloaded_percentage: percentage, greetings: greetings} = model) do
    cols =
      :io.columns()
      |> elem(1)
      |> div(2)

    message = String.pad_leading(greetings, cols + 10)

    view(top_bar: to_bar(cols), bottom_bar: bottom_bar(percentage)) do
      Helpers.blank_rows(7)

      row do
        column size: 12 do
          label(content: message, color: :yellow)
          Helpers.blank_rows(3)

          message_when_greeting(greetings, cols)
        end
      end

      Helpers.render_error(model)
    end
  end

  defp bottom_bar(percentage) do
    progress_bar(percentage: percentage)
  end

  defp to_bar(cols) do
    message = String.pad_leading("Your manga is downloading!", cols)

    row do
      column size: 12 do
        panel do
          label(color: :white, content: "#{message}")
        end
      end
    end
  end

  defp message_when_greeting(greetings, cols) when greetings != "" do
    message = String.pad_leading("Press ESC to go back to the beginning or Q to exit", cols + 17)

    label(content: message, color: :white)
  end

  defp message_when_greeting(_greetings, _cols) do
    label(content: "", color: :white)
  end
end
