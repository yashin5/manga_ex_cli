defmodule MangaExCli.CliUI do
  @label_color 15
  @input_color 183
  @input_text_color 53
  @background_color 53
  @input_size 20
  @error_color 9

  def draw_input(
        message \\ "",
        error_message \\ false,
        input \\ false,
        options \\ false,
        input_row \\ false
      ) do
    {rows, cols} = screen_size()

    # floor to get the line just above center when rows or cols is odd
    # truncate to convert float to integer
    row = Float.floor(rows / 2) |> trunc()
    column = Float.floor((cols - @input_size) / 2) |> trunc()

    # move the cursor to that position and draw the label
    if message !== "" do
      if options do
        IO.puts("\n\n")

        IO.puts(IO.ANSI.cursor(row + 5, column) <> IO.ANSI.color(50) <> "Options")

        message
        |> Enum.zip(7..200)
        |> Enum.each(fn {option, index} ->
          IO.puts(IO.ANSI.cursor(row + index, column) <> IO.ANSI.color(@label_color) <> option)
        end)

        IO.puts("\n\n")
      else
        unless input_row do
          IO.write(IO.ANSI.cursor(row, column) <> IO.ANSI.color(@label_color) <> message)

          IO.puts("\n")
        end
      end
    end

    if input do
      if input_row do
        IO.puts("\n")

        IO.write(
          IO.ANSI.cursor(input_row + 1 + row, column) <> IO.ANSI.color(50) <> message
        )

        IO.puts IO.ANSI.color_background(@background_color) <> ""
    IO.write(IO.ANSI.cursor(input_row + 2 + row, column) <> IO.ANSI.color_background(@input_color) <> IO.ANSI.color(@input_text_color))
      else
        input_box(column, row)
      end
    end

    if error_message  do
      if input_row do
        IO.puts(
          IO.ANSI.cursor(input_row + 3 + row, column) <>
            IO.ANSI.color_background(@error_color) <> IO.ANSI.color(@label_color) <> error_message
        )

        input_box(column, row + input_row - 1)

    IO.puts IO.ANSI.color_background(@background_color) <> ""
    IO.write(IO.ANSI.cursor(input_row + 2 + row, column) <> IO.ANSI.color_background(@input_color) <> IO.ANSI.color(@input_text_color))
    end
  end
  end

  defp input_box(column, row) do
    # move the cursor down a line and draw the input
    IO.write(
      IO.ANSI.cursor(row + 3, column) <>
        IO.ANSI.color_background(@input_color) <> String.duplicate(" ", @input_size)
    )

    # move the cursor to the beginning of the input
    IO.write(IO.ANSI.cursor(row + 3, column) <> IO.ANSI.color(@input_text_color))
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
