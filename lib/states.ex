defmodule MangaExCli.States do
  @moduledoc false
  import Ratatouille.Constants, only: [key: 1]

  alias MangaExCli.Cli
  alias MangaExCli.PercentageMonitor
  alias MangaExCli.RowsMonitor
  alias MangaExCli.Views.SelectChapters
  alias MangaExCli.Views.SelectDesiredManga
  alias MangaExCli.Views.SelectLanguage
  alias MangaExCli.Views.SelectManga
  alias MangaExCli.Views.SelectProvider

  @delete_keys [
    key(:delete),
    key(:backspace),
    key(:backspace2)
  ]
  @spacebar key(:space)
  @enter key(:enter)
  @esc key(:esc)

  def update(model, message) do
    RowsMonitor.update_rows()

    updated_model_with_pages = update_models_pages(model)

    case message do
      {:event, %{key: @esc}} ->
        case updated_model_with_pages do
          %{help?: true} ->
            %{updated_model_with_pages | help?: false}

          %{screen: :downloading_chapters} ->
            PercentageMonitor.update_percentage(0)
            Cli.init(nil)

          %{
            screen: :select_chapters,
            selected_manga: selected_manga,
            manga_list: manga_list,
            desired_language: language,
            desired_provider: provider,
            manga_list_with_positions: manga_list_with_positions,
            providers: providers
          } ->
            Cli.init(nil)
            |> Map.merge(%{
              total_chapters: [],
              chapters: [],
              special_chapters: [],
              selected_manga: selected_manga,
              manga_list: manga_list,
              screen: :select_desired_manga,
              manga_list_with_positions: manga_list_with_positions,
              pages: length(Enum.chunk_every(manga_list, RowsMonitor.get_rows_to_use())),
              desired_language: language,
              desired_provider: provider,
              providers: providers
            })

          %{
            screen: :select_desired_manga,
            desired_language: language,
            desired_provider: provider,
            providers: providers
          } ->
            Cli.init(nil)
            |> Map.merge(%{
              screen: :select_manga,
              desired_language: language,
              desired_provider: provider,
              providers: providers
            })

          %{
            screen: :select_manga,
            desired_language: language,
            providers_and_languages: providers_and_languages
          } ->
            Map.merge(Cli.init(nil), %{
              desired_language: language,
              screen: :select_provider,
              providers: Map.get(providers_and_languages, language)
            })

          %{screen: :select_provider} ->
            Cli.init(nil)

          %{screen: :select_language} ->
            %{updated_model_with_pages | desired_language: "", providers: []}

          _ ->
            updated_model_with_pages
        end
        |> Map.merge(%{text: "", error: ""})

      {:event, %{key: @enter}} ->
        if updated_model_with_pages.text != "" do
          case updated_model_with_pages do
            %{text: ":" <> text} when text in ["h", "H"] ->
              %{updated_model_with_pages | help?: true}

            %{text: ":" <> text} ->
              change_page(updated_model_with_pages, text)

            %{desired_language: ""} ->
              SelectLanguage.update(updated_model_with_pages)

            %{desired_provider: ""} ->
              SelectProvider.update(updated_model_with_pages)

            %{selected_manga: ""} ->
              SelectManga.update(updated_model_with_pages)

            %{desired_manga: ""} ->
              SelectDesiredManga.update(updated_model_with_pages)

            %{desired_chapters: ""} ->
              SelectChapters.update(updated_model_with_pages)

            _ ->
              updated_model_with_pages
          end
          |> case do
            {model, func} -> {Map.put(model, :text, ""), func}
            model -> model |> Map.put(:text, "")
          end
        else
          %{updated_model_with_pages | error: "Can't be blank"}
        end

      {:event, %{key: key}} when key in @delete_keys ->
        %{updated_model_with_pages | text: String.slice(updated_model_with_pages.text, 0..-2)}

      {:event, %{key: @spacebar}} ->
        %{updated_model_with_pages | text: updated_model_with_pages.text <> " "}

      {:event, %{ch: ch}} when ch > 0 ->
        %{updated_model_with_pages | text: updated_model_with_pages.text <> <<ch::utf8>>}

      {:downloading, {model, percentage}} ->
        updated_model = %{model | downloaded_percentage: percentage}

        {updated_model, SelectChapters.update_percent_view(updated_model)}

      {:fully_downloaded, model} ->
        %{model | greetings: "Your manga has successfully downloaded"}

      _ ->
        updated_model_with_pages
    end
  end

  defp change_page(%{pages: pages} = model, text) do
    try do
      to_page = String.to_integer(text)

      case to_page in 1..pages do
        true ->
          %{model | actual_page: to_page, text: ""}

        _ ->
          %{model | error: "Page does not exist"}
      end
    rescue
      _ ->
        %{model | error: "Invalid page"}
    end
  end

  defp update_models_pages(model) do
    model
    |> Map.put(
      :pages,
      length_to_use_as_page(model)
      |> Enum.chunk_every(RowsMonitor.get_rows_to_use())
      |> length()
    )
  end

  defp length_to_use_as_page(%{
         screen: screen,
         manga_list: manga_list,
         total_chapters: total_chapters
       }) do
    cond do
      screen == :select_desired_manga and manga_list != [] ->
        manga_list

      screen == :select_chapters and total_chapters != [] ->
        1..length(total_chapters)

      true ->
        1..1
    end
  end
end
