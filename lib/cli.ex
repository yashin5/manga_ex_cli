defmodule MangaExCli.Cli do
  alias MangaExCli

  manga_ex = Path.expand("./manga_ex_cli")
  manga_ex_alias = "\nalias manga_ex='#{manga_ex}'"

  # adding on bashrc
  bashrc = Path.expand("~/.bashrc")

  bashrc
  |> File.read()
  |> case do
    {:error, :enoent} ->
      :ok

    {:ok, file_content} ->
      unless String.contains?(file_content, manga_ex_alias) do
        bashrc |> File.write(file_content <> manga_ex_alias)
      end
  end

  # adding on zshrc
  zshrc = Path.expand("~/.zshrc")

  zshrc
  |> File.read()
  |> case do
    {:error, :enoent} ->
      :ok

    {:ok, file_content} ->
      unless String.contains?(file_content, manga_ex_alias) do
        zshrc |> File.write(file_content <> manga_ex_alias)
      end
  end

  @spec main(any) :: none
  def main(_args \\ []) do
    IO.puts("Welcome to MangaEX!")
    manga_name = IO.gets("\n\nmanga name: ") |> String.replace("\n", "")

    choose_manga_language()
    |> choose_manga_provider()
    |> choose_manga(manga_name)
  end

  defp choose_manga_language() do
    languages_and_providers = %{"pt-br" => ["mangahost"], "en" => ["mangakakalot"]}
    Enum.each(Map.keys(languages_and_providers), fn languages ->
      IO.puts("\n#{languages}")
    end)
    desired_language = IO.gets("\n\nSelect the desired language: ") |> String.replace("\n", "")


    if desired_language in Map.keys(languages_and_providers) do
      ["mangahost"]

    else
      IO.puts("\n\nWrong option. try again")
      choose_manga_language()

    end
  end

  defp choose_manga_provider(manga_providers) do
    Enum.each(manga_providers, fn manga_providers ->
      IO.puts("\n#{manga_providers}")
    end)

    wanted_manga_provider = IO.gets("\n\ntype the desired manga provider: ") |> String.replace("\n", "")

    if wanted_manga_provider in manga_providers do
      manga_providers
      |> Enum.filter(&(&1 == wanted_manga_provider))
      |> List.last()

    else
      IO.puts("\n\nWrong option. try again")
      choose_manga_provider(manga_providers)

    end
  end

  defp choose_manga(manga_provider, manga_name) do
    mangas_with_positions = manga_name
    |> MangaEx.MangaProviders.Mangahost.find_mangas()
    |> generate_array_with_index()

    mangas_with_positions
    |> Enum.each(fn {index, {manga_name, _manga_url}} ->
      IO.puts("\n#{index} - #{manga_name}")
    end)

    wanted_manga =
      IO.gets("\n\ntype position of manga that you want: ") |> String.replace("\n", "")

    [{_, {manga_name, manga_url}}] =
      mangas_with_positions
      |> Enum.filter(fn {index, {_manga_name, _manga_url}} ->
        "#{index}" == wanted_manga
      end)

    IO.puts("\nyou choose #{wanted_manga} - #{manga_name}")

    choose_chapters(manga_url, manga_provider)
  end

  defp choose_chapters(manga_url, manga_provider) do
    wanted_chapters = IO.gets("\nwhich chapters do you want: ") |> String.replace("\n", "")

    if wanted_chapters in ["todos", "all"] do
      MangaExCli.download_chapters(manga_url, :all_chapters, String.to_atom(manga_provider))
    end

    main()
  end

  defp generate_array_with_index(array) do
    1
    |> Range.new(length(array))
    |> Enum.zip(array)
  end
end
