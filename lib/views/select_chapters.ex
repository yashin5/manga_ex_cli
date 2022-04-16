defmodule MangaExCli.Views.SelectChapters do
  import Ratatouille.View

  alias MangaExCli.Helpers

  def render(
        %{
          desired_manga: {manga_name, _},
          chapters: chapters,
          text: text
        } = model
      ) do
    func_to_map_in_chunk = fn {index, {_, chapter}} ->
      label(color: :white, content: "#{index} - #{manga_name} CHAP #{chapter}")
    end

    view(top_bar: Helpers.render_welcome_message()) do
      overlay do
        viewport do
          panel height: :fill do
            label(content: "Type the desired chapters: " <> text <> "▌")

            panel title: "Chapters", height: :fill do
              Helpers.chunk_by_type(model, chapters, func_to_map_in_chunk)
            end
          end
        end
      end

      Helpers.pages(model)
      Helpers.render_error(model)
    end
  end
end
