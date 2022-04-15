defmodule MangaExCli.Cli do
  alias MangaExCli
  alias MangaExCli.Views.SelectLanguage
  alias MangaExCli.Views.SelectProvider
  alias MangaExCli.Views.SelectManga
  alias MangaExCli.Views.SelectDesiredManga
  alias MangaExCli.Views.DownloadingChapters
  alias MangaExCli.Views.SelectChapters
  alias MangaExCli.States

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

  def init(_context) do
    %{
      text: "",
      error: "",
      greetings: "",
      downloaded_percentage: 0,
      manga_downloaded?: false,
      pages: 1,
      actual_page: 1,
      chapters: [],
      desired_provider: "",
      providers: [],
      desired_manga: "",
      selected_manga: "",
      desired_chapters: "",
      manga_list: [],
      manga_list_with_positions: [],
      desired_language: "",
      providers_and_languages: MangaEx.Options.possible_languages_and_providers()
    }
  end

  defdelegate update(model, message), to: States

  def main(_), do: Ratatouille.run(__MODULE__)

  def render(model), do: do_render(model)

  defp do_render(%{desired_language: ""} = model), do: SelectLanguage.render(model)
  defp do_render(%{desired_provider: ""} = model), do: SelectProvider.render(model)
  defp do_render(%{selected_manga: ""} = model), do: SelectManga.render(model)
  defp do_render(%{desired_manga: ""} = model), do: SelectDesiredManga.render(model)

  defp do_render(%{desired_chapters: "", manga_downloaded?: true} = model),
    do: SelectLanguage.render(model)

  defp do_render(%{desired_chapters: ""} = model), do: SelectChapters.render(model)
  defp do_render(%{manga_downloaded?: false} = model), do: DownloadingChapters.render(model)
end
