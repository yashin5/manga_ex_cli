defmodule MangaExCli.Views.SelectChapters do
  import Ratatouille.View

  alias MangaExCli.Helpers
  alias MangaExCli.PercentageMonitor
  alias Ratatouille.Runtime.Command

  def render(
        %{
          desired_manga: {manga_name, _},
          total_chapters: total_chapters,
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
              Helpers.chunk_by_type(
                model,
                Helpers.generate_array_with_index(total_chapters),
                func_to_map_in_chunk
              )
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
          text: text,
          desired_manga: {manga_name, _manga_url},
          desired_provider: desired_provider
        } = model
      ) do
    chapters_to_download = get_chapters(text, model)

    if is_binary(chapters_to_download) do
      %{model | error: chapters_to_download}
    else
      Task.async(fn ->
        download(chapters_to_download, manga_name, desired_provider)
      end)

      updated_model = %{
        model
        | screen: :downloading_chapters,
          desired_chapters: :ok,
          error: "",
          text: ""
      }

      {updated_model, update_percent_view(updated_model)}
    end
  end

  defp get_chapters("all-chapters", %{chapters: chapters}), do: chapters

  defp get_chapters("all-special", %{special_chapters: chapters}), do: chapters

  defp get_chapters("all", %{total_chapters: total_chapters}), do: total_chapters

  defp get_chapters(text, %{
         chapters: possible_chapters,
         special_chapters: possible_special_chapters,
         total_chapters: total_chapters
       }) do
    cond do
      String.contains?(text, "~") ->
        [chapters, special_chapters] = String.split(text, "~")

        with [_ | _] = handled_chapters <- handle_chapters(chapters, possible_chapters, :chapter),
             [_ | _] = handled_special_chapters <-
               handle_chapters(special_chapters, possible_special_chapters, :special_chapter) do
          handled_special_chapters ++ handled_chapters
        else
          error -> error
        end

      String.contains?(text, "-") ->
        text
        |> handle_pontuactions(possible_chapters, "-")
        |> handle_chapters_result(possible_chapters)

      String.contains?(text, ",") ->
        text
        |> handle_pontuactions(total_chapters, ",", "chapter/special chapter")
        |> handle_chapters_result(total_chapters)

      true ->
        "Invalid"
    end
  end

  def update_percent_view(%{downloaded_percentage: percentage} = model) when percentage < 100 do
    Command.new(
      fn ->
        {model, PercentageMonitor.get_actual_percentage()}
      end,
      :downloading
    )
  end

  def update_percent_view(model) do
    Command.new(
      fn ->
        model
      end,
      :fully_downloaded
    )
  end

  defp download(chapters, manga_name, desired_provider) do
    MangaExCli.download_chapters(
      chapters,
      manga_name,
      String.to_atom(desired_provider)
    )
  end

  Enum.each(["chapter", "special chapter"], fn type ->
    type_to_match = type |> String.replace(" ", "_") |> String.to_atom()

    defp handle_chapters(typed_chapters, possible_chapters, unquote(type_to_match)) do
      if String.contains?(typed_chapters, "-") do
        handle_pontuactions(
          typed_chapters,
          possible_chapters,
          "-"
        )
      else
        handle_pontuactions(typed_chapters, possible_chapters, ",", unquote(type))
      end
      |> handle_chapters_result(possible_chapters)
    end
  end)

  defp handle_chapters_result(result, possible_chapters) do
    case result do
      [_ | _] = chapters ->
        Enum.map(chapters, fn chapter ->
          Enum.find(possible_chapters, fn {_url, possible_chapter} ->
            chapter == possible_chapter
          end)
        end)

      error ->
        error
    end
  end

  def handle_pontuactions(typed_chapters, possible_chapters, "-") do
    try do
      possible_chapters_number = get_chapters_number(possible_chapters)

      [start_chapter, end_chapter] =
        typed_chapters |> String.split("-") |> Enum.map(&String.to_integer/1)

      if start_chapter in possible_chapters_number and end_chapter in possible_chapters_number do
        Enum.map(start_chapter..end_chapter, & &1)
      else
        "Some Chapter is out of range"
      end
    rescue
      _ ->
        "Special chapters only can be downloaded when type separated with commas and 'all'"
    end
  end

  def handle_pontuactions(typed_chapters, possible_chapters, ",", type) do
    chapters_to_download =
      typed_chapters
      |> String.split(",")
      |> Enum.map(fn i ->
        try do
          String.to_integer(i)
        rescue
          _ -> i
        end
      end)

    chapters_filtered =
      Enum.map(chapters_to_download, fn chapter ->
        Enum.find(possible_chapters, fn {_url, chapter_number} ->
          chapter_number == chapter
        end)
      end)

    if length(chapters_filtered) == length(chapters_to_download) do
      chapters_to_download
    else
      "Some invalid #{type} is invalid"
    end
  end

  defp get_chapters_number(possible_chapters), do: Enum.map(possible_chapters, &elem(&1, 1))
end
