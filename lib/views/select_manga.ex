defmodule MangaExCli.Views.SelectManga do
  import Ratatouille.View

  alias MangaExCli.Helpers

  def render(%{text: text} = model) do
    view(top_bar: Helpers.render_welcome_message()) do
      overlay do
        viewport do
          panel height: :fill do
            label(content: "Type de desired manga name: " <> text <> "▌")

            panel title: "Mangas" do
            end
          end
        end
      end

      Helpers.render_error(model)
    end
  end
end
