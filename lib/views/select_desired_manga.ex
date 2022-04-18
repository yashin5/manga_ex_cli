defmodule MangaExCli.Views.SelectDesiredManga do
  import Ratatouille.View

  alias MangaExCli.Helpers
  alias MangaExCli.RowsMonitor

  def render(%{text: text, manga_list_with_positions: manga_list_with_positions} = model) do
    func_to_map_in_chunk = fn {index, {manga_name, _}} ->
      name_with_index = "#{index} - #{manga_name}"

      if text == "#{index}" and text != "" do
        label(color: :yellow, content: name_with_index)
      else
        label(color: :white, content: name_with_index)
      end
    end

    view(top_bar: Helpers.render_welcome_message()) do
      overlay do
        viewport do
          panel height: :fill do
            label(content: "Type de desired manga name: " <> text <> "▌")

            panel title: "Mangas", height: :fill do
              Helpers.chunk_by_type(model, manga_list_with_positions, func_to_map_in_chunk)
            end
          end
        end
      end

      Helpers.pages(model)
      Helpers.render_error(model)
    end
  end

  def update(
        %{
          text: inputed_option,
          manga_list_with_positions: manga_list_with_positions,
          desired_provider: desired_provider
        } = model
      ) do
    manga_list_with_positions
    |> Enum.find(fn {index, _} ->
      Integer.to_string(index) == inputed_option
    end)
    |> case do
      {_index, nil} ->
        %{model | selected_manga: "", error: "Manga is not in list"}

      nil ->
        %{model | selected_manga: "", error: "Manga is not in list"}

      {_index, desired_manga} ->
        {_manga_name, manga_url} = desired_manga

        desired_provider
        |> String.to_atom()
        |> MangaEx.get_chapters(manga_url)
        |> do_update(model, desired_manga)
    end
  end

  defp do_update(
         %{chapters: chapters, special_chapters: special_chapters},
         model,
         desired_manga
       ) do
    total_chapters = Enum.reverse(special_chapters ++ chapters)
    total_chapters_length = length(total_chapters)

    %{
      model
      | desired_manga: desired_manga,
        error: "",
        screen: :select_chapters,
        actual_page: 1,
        chapters: chapters,
        special_chapters: special_chapters,
        total_chapters: total_chapters,
        pages:
          1..total_chapters_length
          |> Enum.chunk_every(RowsMonitor.get_rows_to_use())
          |> length()
    }
  end

  defp do_update(_, model, _desired_manga) do
    %{
      model
      | selected_manga: "",
        error: "Could not get the chapters"
    }
  end
end
