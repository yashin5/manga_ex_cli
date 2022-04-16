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

  def update_event(
        %{
          text: inputed_option,
          manga_list_with_positions: manga_list_with_positions,
          desired_provider: desired_provider
        } = model
      ) do
    {_index, desired_manga} =
      Enum.find(manga_list_with_positions, fn {index, _} ->
        Integer.to_string(index) == inputed_option
      end)

    if is_nil(desired_manga) do
      %{model | selected_manga: "", error: "Manga is not in list"}
    else
      {_manga_name, manga_url} = desired_manga

      desired_provider
      |> String.to_atom()
      |> MangaEx.get_chapters(manga_url)
      |> do_update_event(model, desired_manga)
    end
  end

  defp do_update_event(
         %{chapters: chapters, special_chapters: special_chapters},
         model,
         desired_manga
       ) do
    chapters_length = length(special_chapters ++ chapters)

    %{
      model
      | desired_manga: desired_manga,
        error: "",
        screen: :select_chapters,
        actual_page: 1,
        chapters:
          chapters
          |> Enum.concat(special_chapters)
          |> Enum.reverse()
          |> Helpers.generate_array_with_index(),
        pages:
          Enum.chunk_every(
            1..chapters_length,
            RowsMonitor.get_rows_to_use()
          )
          |> length()
    }
  end

  defp do_update_event(_, model, _desired_manga) do
    %{
      model
      | selected_manga: "",
        error: "Could not get the chapters"
    }
  end
end
