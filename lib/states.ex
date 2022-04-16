defmodule MangaExCli.States do
  import Ratatouille.Constants, only: [key: 1]

  alias MangaExCli.Cli
  alias MangaExCli.RowsMonitor

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

            %{desired_language: "", text: text, providers_and_languages: providers_and_languages} ->
              language =
                providers_and_languages
                |> Map.keys()
                |> Enum.filter(&(&1 == text))

              case language do
                [] ->
                  %{updated_model_with_pages | error: "Invalid language"}

                [language | _] ->
                  %{
                    updated_model_with_pages
                    | desired_language: updated_model_with_pages.text,
                      error: "",
                      screen: :select_provider,
                      providers: Map.get(providers_and_languages, language)
                  }
              end

            %{
              desired_provider: "",
              providers_and_languages: providers_and_languages,
              text: text,
              desired_language: desired_language
            } ->
              if text in (providers_and_languages
                          |> Enum.filter(fn {language, _} -> language == desired_language end)
                          |> Enum.flat_map(&elem(&1, 1))) do
                %{
                  updated_model_with_pages
                  | screen: :select_manga,
                    desired_provider: text,
                    error: ""
                }
              else
                %{updated_model_with_pages | error: "Invalid provider"}
              end

            %{selected_manga: "", text: text, desired_provider: desired_provider} ->
              desired_provider
              |> String.to_atom()
              |> MangaEx.find_mangas(text)
              |> case do
                {:ok, :manga_not_found} ->
                  %{updated_model_with_pages | selected_manga: "", error: "Manga not found"}

                manga_list ->
                  %{
                    updated_model_with_pages
                    | selected_manga: text,
                      manga_list: manga_list,
                      screen: :select_desired_manga,
                      manga_list_with_positions: generate_array_with_index(manga_list),
                      pages: length(Enum.chunk_every(manga_list, RowsMonitor.get_rows_to_use())),
                      error: ""
                  }
              end

            %{
              desired_manga: "",
              text: inputed_option,
              manga_list_with_positions: manga_list_with_positions,
              desired_provider: desired_provider
            } ->
              {_index, desired_manga} =
                Enum.find(manga_list_with_positions, fn {index, _} ->
                  Integer.to_string(index) == inputed_option
                end)

              if is_nil(desired_manga) do
                %{updated_model_with_pages | selected_manga: "", error: "Manga is not in list"}
              else
                {_manga_name, manga_url} = desired_manga

                desired_provider
                |> String.to_atom()
                |> MangaEx.get_chapters(manga_url)
                |> case do
                  %{chapters: chapters, special_chapters: special_chapters} ->
                    chapters_length = length(special_chapters ++ chapters)

                    %{
                      updated_model_with_pages
                      | desired_manga: desired_manga,
                        error: "",
                        screen: :select_chapters,
                        actual_page: 1,
                        chapters:
                          chapters
                          |> Enum.concat(special_chapters)
                          |> Enum.reverse()
                          |> generate_array_with_index(),
                        pages:
                          Enum.chunk_every(
                            1..chapters_length,
                            RowsMonitor.get_rows_to_use()
                          )
                          |> length()
                    }

                  _ ->
                    %{
                      updated_model_with_pages
                      | selected_manga: "",
                        error: "Could not get the chapters"
                    }
                end
              end

            %{
              desired_chapters: "",
              desired_manga: {manga_name, manga_url},
              desired_provider: desired_provider
            } = updated_model_with_pages ->
              Task.async(fn ->
                MangaExCli.download_chapters(
                  manga_url,
                  manga_name,
                  :all_chapters,
                  String.to_atom(desired_provider)
                )
              end)

              updated_model = %{
                updated_model_with_pages
                | screen: :downloading_chapters,
                  desired_chapters: :ok
              }

              {updated_model, update_cmd(updated_model)}

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

        {updated_model, update_cmd(updated_model)}

      {:fully_downloaded, model} ->
        %{model | greetings: "Your manga has successfully downloaded"}

      _ ->
        updated_model_with_pages
    end
  end

  defp update_cmd(%{downloaded_percentage: percentage} = model) when percentage < 100 do
    Ratatouille.Runtime.Command.new(
      fn ->
        {model, MangaExCli.PercentageMonitor.get_actual_percentage()}
      end,
      :downloading
    )
  end

  defp update_cmd(model) do
    Ratatouille.Runtime.Command.new(
      fn ->
        model
      end,
      :fully_downloaded
    )
  end

  defp generate_array_with_index(array) do
    1
    |> Range.new(length(array))
    |> Enum.zip(array)
  end
end
