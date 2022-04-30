# MangaExCli

## Dependencies
To use this, you need [elixir](https://elixir-lang.org/) and [erlang](https://www.erlang.org/downloads.html) installed.

## Installation
Go to the project's root folder and run:

 ``` mix deps.get```

After done, run:

``` mix escript.build```

Now you can run the application by typing

```manga_ex```

## Commands
- **Enter** to go forwards
- **Esc** to go backwards
- **Q** to exit
- **-** to separate chapters in some range
- **,** to separate for each chapter
- **~** to separate chapters from special chapters. **Chapters must be in left and special chapters in the right
- To download all chapters, you have three options:
  - **all-chapters** to download all non-special chapters 
  - **all-special** to download all special chapters
  - **all to** download both 