# MangaExCli

## About the project

That project aims to turn a little more easy to download the mangas that you desire. It's hard to find complete volumes for download and it's really annoying when the place you like to read or download manga is full of ads(usually they ask you to disable the AD block).

In a near future we will have more providers and more languages available.
![Peek 2022-04-30 17-47](https://user-images.githubusercontent.com/31665100/166122157-46de8ded-e221-4f3a-97aa-4a34e4fd22f5.gif)


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
- **:h** to go to help page
- **:<page>** when a screen have more than one page, you need to use :<page> to move around them, like: :22
- **-** to separate chapters in some range, like: 1-125 **It Does not work for special chapters
- **,** to separate for each chapter, like: 1,2,3,4
- **~** to separate chapters from special: 1-125~700.1,700.5
chapters. **Chapters must be in left and special chapters in the right
- To download all chapters, you have three options:
  - **all-chapters** to download all non-special chapters 
  - **all-special** to download all special chapters
  - **all to** download both 


## OBS
- When you already have a folder with the manga name, the app will not delete or remove anything.
- The app always verify if chapter already existis in your folder before download.
- This app is just a application CLI to a scrapper, it only download images from the listed providers.
