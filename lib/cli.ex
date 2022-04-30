defmodule MangaExCli.Cli do
  alias MangaExCli.States

  @screens %{
    select_language: MangaExCli.Views.SelectLanguage,
    select_provider: MangaExCli.Views.SelectProvider,
    select_manga: MangaExCli.Views.SelectManga,
    select_desired_manga: MangaExCli.Views.SelectDesiredManga,
    select_chapters: MangaExCli.Views.SelectChapters,
    downloading_chapters: MangaExCli.Views.DownloadingChapters
  }

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
      screen: :select_language,
      help?: false,
      text: "",
      error: "",
      greetings: "",
      downloaded_percentage: 0,
      manga_downloaded?: false,
      pages: 1,
      actual_page: 1,
      chapters: [],
      special_chapters: [],
      total_chapters: [],
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

  def render(%{help?: false} = model) do
    do_render(model)
  end

  def render(_model) do
    MangaExCli.Helpers.help()
  end

  defp do_render(%{screen: screen} = model), do: @screens[screen].render(model)
end
