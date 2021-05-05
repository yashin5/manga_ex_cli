defmodule MangaExCli do
  @moduledoc """
  Documentation for `MangaExCli`.
  """
  alias MangaEx.MangaProviders.Mangahost

  @spec download_chapters(String.t(), String.t() | integer(), String.t() | integer(), atom()) ::
          :ok | {:error, :chapters_out_of_range}
  def download_chapters(manga_url, from, to, :mangahost) do
    %{chapters: chapters} = Mangahost.get_chapters(manga_url)

    if from in chapters and to in chapters do
      get_chapters_pages(manga_url, from..to)
    else
      {:error, :chapters_out_of_range}
    end
  end

  @spec download_chapters(String.t(), atom(), atom()) :: :ok
  def download_chapters(manga_url, :all_chapters, :mangahost) do
    manga_url = String.replace(manga_url, "\n", "")
    %{chapters: chapters} = Mangahost.get_chapters(manga_url)
    manga_name = get_manga_name(manga_url)

    chapters_count = length(chapters)

    chapters
    |> Enum.reverse()
    |> Enum.each(fn chapter ->
      do_download_chapters(manga_url, chapter, manga_name, chapters_count)
    end)
  end

  defp do_download_chapters(manga_url, chapter, manga_name, chapters_count) do
    manga_url
    |> Mangahost.generate_chapter_url(chapter)
    |> Mangahost.get_pages(manga_name)
    |> Mangahost.download_pages(manga_name, chapter)
    |> case do
      result when result == [] ->
        :timer.sleep(:timer.seconds(1))
        do_download_chapters(manga_url, chapter, manga_name, chapters_count)

      result ->
        verify_each_download =
          result
          |> Enum.map(fn chapter_download_result ->
            case chapter_download_result do
              status when status in [{:ok, :page_downloaded}, {:ok, :page_already_downloaded}] ->
                status

              _ ->
                :timer.sleep(:timer.seconds(1))
                do_download_chapters(manga_url, chapter, manga_name, chapters_count)
            end
          end)

        all_chapter_already_download =
          Enum.all?(verify_each_download, &(&1 == {:ok, :page_already_downloaded}))

        if all_chapter_already_download do
          ProgressBar.render(chapter, chapters_count, suffix: :count)

        else
          ProgressBar.render(chapter, chapters_count, suffix: :count)

          :timer.sleep(:timer.seconds(1))
        end
    end
  end

  defp get_chapters_pages(manga_url, chapters) do
    manga_name = get_manga_name(manga_url)

    Enum.each(chapters, fn chapter ->
      manga_url
      |> Mangahost.generate_chapter_url(chapter)
      |> Mangahost.get_pages(manga_name)
      |> Mangahost.download_pages(manga_name, chapter)
    end)
  end

  defp get_manga_name(manga_url) do
    [_, _, _, manga_name, _] = manga_url |> String.split(["/", "-mh"], trim: true)
    manga_name
  end
end
