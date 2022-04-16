defmodule MangaExCli.Views.SelectProvider do
  import Ratatouille.View

  alias MangaExCli.Helpers

  def render(%{text: text, providers: providers} = model) do
    view(top_bar: Helpers.render_welcome_message()) do
      overlay do
        viewport do
          panel height: :fill do
            label(content: "Select the desired provider: " <> text <> "▌")

            panel title: "Providers", height: :fill do
              Helpers.filter_by_typed_text(text, providers)
            end
          end
        end
      end

      Helpers.render_error(model)
    end
  end
end
