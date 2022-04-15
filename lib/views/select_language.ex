defmodule MangaExCli.Views.SelectLanguage do
  import Ratatouille.View

  alias MangaExCli.Helpers

  def render(%{text: text, providers_and_languages: providers_and_languages} = model) do
    filtered_providers =
      providers_and_languages
      |> Map.keys()
      |> Enum.filter(&String.contains?(&1, String.downcase(text)))
      |> Enum.map(fn language ->
        color = if text == "", do: :white, else: :yellow
        label(color: color, content: language)
      end)

    view(top_bar: Helpers.render_welcome_message()) do
      overlay do
        viewport do
          panel height: :fill do
            label(content: "Select the desired language: " <> text <> "▌")

            panel title: "Languages", height: :fill do
              filtered_providers
            end
          end
        end
      end

      Helpers.render_error(model)
    end
  end
end
