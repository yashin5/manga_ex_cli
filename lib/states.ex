defmodule MangaExCli.States do
  import Ratatouille.Constants, only: [key: 1]

  alias MangaExCli.Cli
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

  def update(%{screen: screen, manga_list: manga_list, chapters: chapters} = model, message) do
    RowsMonitor.update_rows()

    length_to_use_as_page =
      cond do
        screen == :select_desired_manga and manga_list != [] ->
          manga_list

        screen == :select_chapters and chapters != [] ->
          1..length(chapters)

        true ->
          1..1
      end

    updated_model_with_pages =
      model
      |> Map.put(
        :pages,
        length_to_use_as_page
        |> Enum.chunk_every(RowsMonitor.get_rows_to_use())
        |> length()
      )

    case message do
      {:event, %{key: @esc}} ->
        case updated_model_with_pages do
          %{screen: :downloading_chapters} ->
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
              chapters: [],
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
            %{text: ":" <> text, pages: pages} ->
              try do
                to_page = String.to_integer(text)

                case to_page in 1..pages do
                  true ->
                    %{updated_model_with_pages | actual_page: to_page, text: ""}

                  _ ->
                    %{updated_model_with_pages | error: "Page does not exist"}
                end
              rescue
                _ ->
                  %{updated_model_with_pages | error: "Invalid page"}
              end

            %{desired_language: ""} ->
              SelectLanguage.update_event(updated_model_with_pages)

            %{desired_provider: ""} ->
              SelectProvider.update_event(updated_model_with_pages)

            %{selected_manga: ""} ->
              SelectManga.update_event(updated_model_with_pages)

            %{desired_manga: ""} ->
              SelectDesiredManga.update_event(updated_model_with_pages)

            %{desired_chapters: ""} ->
              SelectChapters.update_event(updated_model_with_pages)

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
end
