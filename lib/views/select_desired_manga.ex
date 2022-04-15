defmodule MangaExCli.Views.SelectDesiredManga do
  import Ratatouille.View

  alias MangaExCli.Helpers

  def render(%{text: text, manga_list_with_positions: manga_list_with_positions} = model) do
    filtered_mangas =
      manga_list_with_positions
      |> Enum.map(fn {index, {manga_name, _}} ->
        if String.contains?("#{index}", text) and text != "" do
          label(color: :yellow, content: "#{index} - #{manga_name}")
        else
          label(color: :white, content: "#{index} - #{manga_name}")
        end
      end)
      |> Enum.chunk_every(9)
      |> Enum.at(model.actual_page - 1)

    view(top_bar: Helpers.render_welcome_message()) do
      overlay do
        viewport do
          panel height: :fill do
            label(content: "Type de desired manga name: " <> text <> "▌")

            panel title: "Mangas", height: :fill do
              filtered_mangas
            end
          end
        end
      end

      Helpers.pages(model)
      Helpers.render_error(model)
    end
  end
end
