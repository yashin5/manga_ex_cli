defmodule MangaExCli.Views.SelectProvider do
  import Ratatouille.View

  alias MangaExCli.Helpers

  def render(%{text: text, providers: providers} = model) do
    filtered_providers =
      providers
      |> Enum.filter(&String.contains?(&1, String.downcase(text)))
      |> Enum.map(fn provider ->
        color = if text == "", do: :white, else: :yellow
        label(color: color, content: provider)
      end)

    view(top_bar: Helpers.render_welcome_message()) do
      overlay do
        viewport do
          panel height: :fill do
            label(content: "Select the desired provider: " <> text <> "▌")

            panel title: "Providers", height: :fill do
              filtered_providers
            end
          end
        end
      end

      Helpers.render_error(model)
    end
  end
end
