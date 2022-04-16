defmodule MangaExCli.Views.SelectLanguage do
  import Ratatouille.View

  alias MangaExCli.Helpers

  def render(%{text: text, providers_and_languages: providers_and_languages} = model) do
    view(top_bar: Helpers.render_welcome_message()) do
      overlay do
        viewport do
          panel height: :fill do
            label(content: "Select the desired language: " <> text <> "▌")

            panel title: "Languages", height: :fill do
              Helpers.filter_by_typed_text(text, Map.keys(providers_and_languages))
            end
          end
        end
      end

      Helpers.render_error(model)
    end
  end
end
