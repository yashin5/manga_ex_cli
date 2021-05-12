defmodule MangaExCli.Cli do
  alias MangaExCli
  alias MangaExCli.CliUI

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
    CliUI.draw_background()

    start_cli()
  end

  defp start_cli() do
    CliUI.draw_background()

    CliUI.draw_input("type the manga name: ", "", true)
    manga_name = IO.gets("") |> String.replace("\n", "")

    choose_manga_language()
    |> choose_manga_provider()
    |> choose_manga(manga_name)
  end

  defp choose_manga_language(wrong_option \\ false) do
    CliUI.draw_background()

    languages_and_providers = MangaEx.Options.possible_languages_and_providers()

    languages_and_providers
    |> Map.keys()
    |> CliUI.draw_input("", false, true)

    CliUI.draw_input("Select the desired language: ", "", true)

    if wrong_option, do: CliUI.draw_input("", "Wrong option. try again", false, false, length(languages_and_providers |> Map.keys()))

    do_choose_manga_language(languages_and_providers)
  end

  defp do_choose_manga_language(languages_and_providers) do
    desired_language = IO.gets("") |> String.replace("\n", "")

    if desired_language in Map.keys(languages_and_providers) do
      languages_and_providers[desired_language]
    else
      choose_manga_language(true)
    end
  end

  defp choose_manga_provider(manga_providers, wrong_option \\ false) do
    CliUI.draw_background()

    CliUI.draw_input(manga_providers, "", false, true)

    CliUI.draw_input("type the desired manga provider", "", true)

    if wrong_option, do: CliUI.draw_input("", "Wrong option. try again", false, false, length(manga_providers))

    do_choose_manga_provider(manga_providers)
  end

  defp do_choose_manga_provider(manga_providers) do
    wanted_manga_provider = IO.gets("") |> String.replace("\n", "")

    if wanted_manga_provider in manga_providers do
      manga_providers
      |> Enum.filter(&(&1 == wanted_manga_provider))
      |> List.last()
    else
      choose_manga_provider(manga_providers, true)
    end
  end

  defp choose_manga(manga_provider, manga_name, wrong_option \\ false) do
    CliUI.draw_background()

    mangas_with_positions =
      manga_name
      |> MangaEx.MangaProviders.Mangahost.find_mangas()
      |> generate_array_with_index()

    mangas_with_positions
    |> Enum.map(fn {index, {manga_name, _manga_url}} ->
      "#{index} - #{manga_name}"
    end)
    |> CliUI.draw_input("", false, true)

    CliUI.draw_input(
      "type position of manga that you want: ",
      "",
      true,
      false,
      length(mangas_with_positions)
    )

    if wrong_option, do: CliUI.draw_input("", "Wrong option. try again", false, false, length(mangas_with_positions))
    do_choose_manga(mangas_with_positions, manga_provider, manga_name)
  end

  defp do_choose_manga(mangas, manga_provider, manga_name) do
    wanted_manga = IO.gets("") |> String.replace("\n", "")

    mangas
    |> Enum.map(fn {index, _} -> "#{index}" end)
    |> Enum.find(&(&1 == wanted_manga))
    |> if do
      CliUI.draw_input("you choose #{wanted_manga} - #{manga_name}")

      [{_, {manga_name, manga_url}}] =
        mangas
        |> Enum.filter(fn {index, {_manga_name, _manga_url}} ->
          "#{index}" == wanted_manga
        end)

      choose_chapters(manga_url, manga_name, manga_provider)
    else
      CliUI.reset()

      choose_manga(manga_provider, manga_name, true)
    end
  end

  defp choose_chapters(manga_url, manga_name, manga_provider) do
    wanted_chapters = IO.gets("\nwhich chapters do you want: ") |> String.replace("\n", "")

    if wanted_chapters in ["todos", "all"] do
      MangaExCli.download_chapters(
        manga_url,
        manga_name,
        :all_chapters,
        String.to_atom(manga_provider)
      )
    end

    start_cli()
  end

  defp generate_array_with_index(array) do
    1
    |> Range.new(length(array))
    |> Enum.zip(array)
  end
end
