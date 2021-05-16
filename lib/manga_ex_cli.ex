defmodule MangaExCli do
  @moduledoc """
  Documentation for `MangaExCli`.
  """
  alias MangaEx.MangaProviders.Mangahost

  # @spec download_chapters(String.t(), String.t() | integer(), String.t() | integer(), atom()) ::
  #         :ok | {:error, :chapters_out_of_range}
  # def download_chapters(manga_url, from, to, :mangahost) do
  #   %{chapters: chapters} = Mangahost.get_chapters(manga_url)

  #   if from in chapters and to in chapters do
  #     get_chapters_pages(manga_url, from..to)
  #   else
  #     {:error, :chapters_out_of_range}
  #   end
  # end

  @spec download_chapters(String.t(), String.t(), atom(), atom()) :: :ok
  def download_chapters(manga_url, manga_name, :all_chapters, :mangahost) do
    manga_url = String.replace(manga_url, "\n", "")
    %{chapters: chapters, special_chapters: special_chapters} = Mangahost.get_chapters(manga_url)
    chapters_count = length(chapters ++ special_chapters)

    (chapters ++ special_chapters)
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.each(fn chapter_and_index ->
      do_download_chapters(manga_url, chapter_and_index, manga_name, chapters_count)
    end)
  end

  # def download_chapters(manga_url, manga_name, :all_chapters, :mangahost) do
  #   manga_url = String.replace(manga_url, "\n", "")
  #   %{chapters: chapters, special_chapters: special_chapters} = Mangahost.get_chapters(manga_url)
  #   chapters_count = length(chapters ++ special_chapters)

  #   (chapters ++ special_chapters)
  #   |> Enum.reverse()
  #   |> Enum.with_index()
  #   |> Enum.each(fn chapter_and_index ->
  #     do_download_chapters(manga_url, chapter_and_index, manga_name, chapters_count)
  #   end)
  # end

  defp do_download_chapters(
         manga_url,
         {chapter, _index} = chapter_and_index,
         manga_name,
         chapters_count
       ) do
    manga_url
    |> Mangahost.generate_chapter_url(chapter)
    |> Mangahost.get_pages(manga_name)
    |> do_download(manga_name, chapter_and_index, chapters_count)
  end

  defp do_download(pages, manga_name, {chapter, index} = chapter_and_index, chapters_count) do
    Mangahost.download_pages(pages, manga_name, chapter)
    |> case do
      result when result == [] ->
        :timer.sleep(:timer.seconds(1))
        do_download(pages, manga_name, chapter_and_index, chapters_count)

      result ->
        verify_each_download =
          result
          |> Enum.map(fn chapter_download_result ->
            case chapter_download_result do
              status when status in [{:ok, :page_downloaded}, {:ok, :page_already_downloaded}] ->
                {:ok, :page_already_downloaded}

              _ ->
                :timer.sleep(:timer.seconds(1))
                do_download(pages, manga_name, chapter_and_index, chapters_count)
            end
          end)

        all_chapter_already_download =
          Enum.all?(verify_each_download, &(&1 == {:ok, :page_already_downloaded}))

        chapter_to_progress_bar = if is_binary(chapter), do: index + 1, else: chapter
        
        ProgressBar.render(chapter_to_progress_bar, chapters_count, suffix: :count)

        unless all_chapter_already_download do
          :timer.sleep(:timer.seconds(1))
          do_download(pages, manga_name, chapter_and_index, chapters_count)
        end
    end
  end

  # defp get_chapters_pages(manga_url, chapters) do
  #   manga_name = get_manga_name(manga_url)

  #   Enum.each(chapters, fn chapter ->
  #     manga_url
  #     |> Mangahost.generate_chapter_url(chapter)
  #     |> Mangahost.get_pages(manga_name)
  #     |> Mangahost.download_pages(manga_name, chapter)
  #   end)
  # end
end
