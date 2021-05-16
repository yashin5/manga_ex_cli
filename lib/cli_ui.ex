defmodule MangaExCli.CliUI do
  @label_color 15
  @input_color 183
  @input_text_color 53
  @background_color 53
  @input_size 20
  @error_color 9

  def draw_input(
        message,
        type,
        input_row \\ 0,
        error \\ false

      ) do
    {rows, cols} = screen_size()

    # floor to get the line just above center when rows or cols is odd
    # truncate to convert float to integer
    row = Float.floor(rows / 2) |> trunc()
    column = Float.floor((cols - @input_size) / 2) |> trunc()

    input(message, type, column, row, input_row, error)
  end

  defp input(error_message, :error, column, row, input_row, error) do
      IO.write(IO.ANSI.color_background(@background_color) <> "")

      input_box(column, input_row + row - 1)
  end

  defp input(message, :input_box, column, row, input_row, error) do
    line_to_skip = if input_row >= 10, do: 3, else: 9
    (0..line_to_skip)
    |> Enum.each(fn i -> IO.puts "\n" end)


    if error do
      message(message, column, row, input_row)

      IO.puts(
        IO.ANSI.cursor(input_row + row + 1, column) <> IO.ANSI.cursor_down() <>
          IO.ANSI.color_background(@error_color) <> IO.ANSI.color(@label_color) <> "Wrong option. try again"
      )

      input_box(column, input_row + row)
    else
      message(message, column, row, input_row)

      input_box(column, input_row + row)
    end

  end

  defp message(message, column, row, input_row \\ 0) do
    IO.puts("\n")

    IO.write(IO.ANSI.cursor(input_row + row, column) <> IO.ANSI.color(50) <> message)

    IO.puts(IO.ANSI.color_background(@background_color) <> "")
  end

  defp input(message, :message, column, row, input_row, error) do
    unless input_row do
      IO.write(IO.ANSI.cursor(row, column) <> IO.ANSI.color(@label_color) <> message)

      IO.puts("\n")
    end
  end

  defp input(messages, :options, column, row, _input_row, error) do
    IO.puts(IO.ANSI.cursor(row + 7, column) <> IO.ANSI.color(50) <> "Options")

    messages
    |> Enum.zip(9..20000)
    |> Enum.each(fn {option, index} ->
      IO.puts(IO.ANSI.cursor(row + index, column) <> IO.ANSI.color(@label_color) <> option)
    end)
  end

  defp input_box(column, row) do
    # move the cursor down a line and draw the input
    IO.write(
      IO.ANSI.cursor(row + 1, column) <>
        IO.ANSI.color_background(@input_color) <> String.duplicate(" ", @input_size)
    )

    # move the cursor to the beginning of the input
    IO.write(IO.ANSI.cursor(row + 1, column) <> IO.ANSI.color(@input_text_color))

  end

  def draw_background do
    IO.write(IO.ANSI.color_background(@background_color) <> IO.ANSI.clear())

    {rows, cols} = screen_size()

    row = Float.floor(rows / 2) |> trunc()
    column = Float.floor((cols - @input_size) / 2) |> trunc()

    IO.write(
      IO.ANSI.cursor(row - 6, column) <>
        IO.ANSI.bright() <> IO.ANSI.color(50) <> "Welcome to MangaEx!"
    )
  end

  defp screen_size do
    {num("lines"), num("cols")}
  end

  def reset do
    IO.write(IO.ANSI.reset() <> IO.ANSI.clear())
  end

  defp num(subcommand) do
    case System.cmd("tput", [subcommand]) do
      {text, 0} ->
        text
        |> String.trim()
        |> String.to_integer()

      _ ->
        0
    end
  end
end
