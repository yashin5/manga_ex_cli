defmodule MangaExCli.States do
  import Ratatouille.Constants, only: [key: 1]

  alias MangaExCli.Cli

  @delete_keys [
    key(:delete),
    key(:backspace),
    key(:backspace2)
  ]
  @spacebar key(:space)
  @enter key(:enter)
  @esc key(:esc)

  def update(model, message) do
    case message do
      {:event, %{key: @esc}} ->
        case model do
          %{selected_manga: manga} when manga != "" ->
            %{model | selected_manga: "", manga_list: [], manga_list_with_positions: []}

          %{desired_provider: provider} when provider != "" ->
            %{model | desired_provider: ""}

          %{desired_language: desired_language} when desired_language != "" ->
            %{model | desired_language: "", providers: []}

          %{desired_provider: desired_provider} when desired_provider != "" ->
            %{model | desired_provider: ""}

          %{selected_manga: selected_manga} when selected_manga != "" ->
            %{
              model
              | selected_manga: "",
                manga_list: [],
                manga_list_with_positions: [],
                pages: 1,
                error: ""
            }

          %{greetings: greetings} when greetings != "" ->
            %{Cli.init(nil) | manga_downloaded?: true}

          _ ->
            model
        end
        |> Map.put(:text, "")

      {:event, %{key: @enter}} ->
        if model.text != "" do
          case model do
            %{text: ":" <> text, pages: pages} ->
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

            %{desired_language: "", text: text, providers_and_languages: providers_and_languages} ->
              language =
                providers_and_languages
                |> Map.keys()
                |> Enum.filter(&(&1 == text))

              case language do
                [] ->
                  %{model | error: "Invalid language", manga_downloaded?: false}

                [language | _] ->
                  %{
                    model
                    | desired_language: model.text,
                      error: "",
                      manga_downloaded?: false,
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
                %{model | desired_provider: text, error: ""}
              else
                %{model | error: "Invalid provider"}
              end

            %{selected_manga: "", text: text, desired_provider: desired_provider} ->
              desired_provider
              |> String.to_atom()
              |> MangaEx.find_mangas(text)
              |> case do
                {:ok, :manga_not_found} ->
                  %{model | selected_manga: "", error: "Manga not found"}

                manga_list ->
                  %{
                    model
                    | selected_manga: text,
                      manga_list: manga_list,
                      manga_list_with_positions: generate_array_with_index(manga_list),
                      pages: length(Enum.chunk_every(manga_list, 9)),
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
                %{model | selected_manga: "", error: "Manga is not in list"}
              else
                {_manga_name, manga_url} = desired_manga

                desired_provider
                |> String.to_atom()
                |> MangaEx.get_chapters(manga_url)
                |> case do
                  %{chapters: chapters, special_chapters: special_chapters} = manga_chapters ->
                    chapters_length = length(special_chapters ++ chapters)

                    %{
                      model
                      | desired_manga: desired_manga,
                        error: "",
                        chapters:
                          chapters
                          |> Enum.concat(special_chapters)
                          |> Enum.reverse()
                          |> generate_array_with_index(),
                        pages: Enum.chunk_every(1..chapters_length, 9) |> length()
                    }

                  _ ->
                    %{model | selected_manga: "", error: "Could not get the chapters"}
                end
              end

            %{
              desired_chapters: "",
              desired_manga: {manga_name, manga_url},
              desired_provider: desired_provider
            } = model ->
              Task.async(fn ->
                MangaExCli.download_chapters(
                  manga_url,
                  manga_name,
                  :all_chapters,
                  String.to_atom(desired_provider)
                )
              end)

              {%{model | desired_chapters: :ok}, update_cmd(%{model | desired_chapters: :ok})}

            _ ->
              model
          end
          |> case do
            {model, func} -> {Map.put(model, :text, ""), func}
            model -> model |> Map.put(:text, "")
          end
        else
          %{model | error: "Can't be blank"}
        end

      {:event, %{key: key}} when key in @delete_keys ->
        %{model | text: String.slice(model.text, 0..-2)}

      {:event, %{key: @spacebar}} ->
        %{model | text: model.text <> " "}

      {:event, %{ch: ch}} when ch > 0 ->
        %{model | text: model.text <> <<ch::utf8>>}

      {:downloading, {model, percentage}} ->
        updated_model = %{model | downloaded_percentage: percentage}

        {updated_model, update_cmd(updated_model)}

      {:fully_downloaded, model} ->
        %{model | greetings: "Your manga has successfully downloaded"}

      _ ->
        model
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
