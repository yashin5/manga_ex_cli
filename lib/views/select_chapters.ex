defmodule MangaExCli.Views.SelectChapters do
  import Ratatouille.View

  alias MangaExCli.Helpers
  alias Ratatouille.Runtime.Command
  alias MangaExCli.PercentageMonitor

  def render(
        %{
          desired_manga: {manga_name, _},
          chapters: chapters,
          text: text
        } = model
      ) do
    func_to_map_in_chunk = fn {index, {_, chapter}} ->
      label(color: :white, content: "#{index} - #{manga_name} CHAP #{chapter}")
    end

    view(top_bar: Helpers.render_welcome_message()) do
      overlay do
        viewport do
          panel height: :fill do
            label(content: "Type the desired chapters: " <> text <> "▌")

            panel title: "Chapters", height: :fill do
              Helpers.chunk_by_type(model, chapters, func_to_map_in_chunk)
            end
          end
        end
      end

      Helpers.pages(model)
      Helpers.render_error(model)
    end
  end

  def update_event(
        %{
          desired_manga: {manga_name, manga_url},
          desired_provider: desired_provider
        } = model
      ) do
    Task.async(fn ->
      MangaExCli.download_chapters(
        manga_url,
        manga_name,
        :all_chapters,
        String.to_atom(desired_provider)
      )
    end)

    updated_model = %{
      model
      | screen: :downloading_chapters,
        desired_chapters: :ok
    }

    {updated_model, update_percent_view(updated_model)}
  end

  def update_percent_view(%{downloaded_percentage: percentage} = model) when percentage < 100 do
    Command.new(
      fn ->
        {model, PercentageMonitor.get_actual_percentage()}
      end,
      :downloading
    )
  end

  def update_percent_view(model) do
    Command.new(
      fn ->
        model
      end,
      :fully_downloaded
    )
  end
end
