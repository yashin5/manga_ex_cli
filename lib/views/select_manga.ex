defmodule MangaExCli.Views.SelectManga do
  import Ratatouille.View

  alias MangaExCli.Helpers
  alias MangaExCli.RowsMonitor

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

  def update_event(%{desired_provider: desired_provider, text: text} = model) do
    desired_provider
    |> String.to_atom()
    |> MangaEx.find_mangas(text)
    |> do_update_event(model, text)
  end

  defp do_update_event({:ok, :manga_not_found}, model, _text) do
    %{model | selected_manga: "", error: "Manga not found"}
  end

  defp do_update_event(manga_list, model, text) do
    %{
      model
      | selected_manga: text,
        manga_list: manga_list,
        screen: :select_desired_manga,
        manga_list_with_positions: Helpers.generate_array_with_index(manga_list),
        pages: length(Enum.chunk_every(manga_list, RowsMonitor.get_rows_to_use())),
        error: ""
    }
  end
end
