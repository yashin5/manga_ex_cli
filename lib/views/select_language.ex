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

  def update_event(%{text: text, providers_and_languages: providers_and_languages} = model) do
    providers_and_languages
    |> Map.keys()
    |> Enum.filter(&(&1 == text))
    |> do_update_event(model, text, providers_and_languages)
  end

  defp do_update_event([], model, _text, _providers_and_languages) do
    %{model | error: "Invalid language"}
  end

  defp do_update_event([language | _], model, text, providers_and_languages) do
    %{
      model
      | desired_language: text,
        error: "",
        screen: :select_provider,
        providers: Map.get(providers_and_languages, language)
    }
  end
end
