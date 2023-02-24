defmodule Spiders.MangayabuSpider do
  # to run iex -S mix run -e "Crawly.Engine.start_spider(Spiders.MangayabuSpider)"
  use Crawly.Spider

  @impl Crawly.Spider
  def base_url do
    "https://mangayabu.top/"
  end

  @impl Crawly.Spider
  def init do
    [start_urls: ["https://mangayabu.top/manga/one-piece/"]]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    case get_manga_info(response.body) do
      %{"allposts" => chapters} ->
        {:ok, _} = save_on_directory(chapters)

        %Crawly.ParsedItem{
          :items => [],
          :requests => chapters |> get_all_urls_from_json() |> create_requests_from_list(response.request_url)
        }
      %{"chapter_name" => _, "chapter_number" => num} ->
        {:ok, chapter_dir_path} = create_dir(num)
        get_and_save_pages(response.body, chapter_dir_path)

        %Crawly.ParsedItem{
          :items => [],
          :requests => []
        }
    end
  end

  @spec create_dir(any()) :: {:ok, any()} | {:error, any()}
  def create_dir(num) do
    one_piece_dir = Path.absname("library/onepiece")
    chapters_dir_path = one_piece_dir <> "/chapters"
    with :ok <- File.mkdir_p(chapters_dir_path),
          :ok = File.mkdir_p(chapters_dir_path <> "/#{num}") do
      {:ok, chapters_dir_path <> "/#{num}"}
    end
  end

  def get_and_save_pages(body, dir_path) do
    {:ok, document} = Floki.parse_document(body)
    pages = Floki.find(document, ".hide-after-a-while ~ img")
    Enum.each(pages, fn page ->
      page_src = Floki.attribute(page, "src") |> List.first()
      page_id = Floki.attribute(page, "id") |> List.first()
      {:ok, response} = HTTPoison.get(page_src)
      File.write(dir_path <> "/#{page_id}.jpg", response.body)
    end)
  end

  def get_all_urls_from_json([%{"chapters" => _, "num" => _} | _] = data) do
    Enum.map(data, &get_all_urls_from_json/1)
  end

  def get_all_urls_from_json(%{"chapters" => [chapter_data], "num" => _}) do
    chapter_data["id"]
  end

  def get_manga_info(body) do
    with {:ok, document} = Floki.parse_document(body) do
      document
        |> Floki.find("#manga-info")
        |> Floki.text(js: true)
        |> Jason.decode!()
    end
  end

  def save_on_directory(data) do
    library = Path.absname("library")
    path = Path.join(library, "onepiece")

    :ok = File.mkdir_p(path)

    path = path <> "/chapters.json"
    File.write(path, Jason.encode!(data))

    {:ok, path}

  end

  def create_requests_from_list(urls, absolute_url) do
      Enum.map(urls, fn url ->
        url
        |> build_absolute_url(absolute_url)
        |> Crawly.Utils.request_from_url()
      end)

  end

  def build_absolute_url(url, request_url) do
    URI.merge(request_url, url) |> to_string()
  end

  # {
  #   "chapters": [
  #     {
  #       "date": "24/04/19",
  #       "id": "https://mangayabu.top/ler/one-piece-capitulo-01-my3414/",
  #       "scan": "",
  #       "scanuri": ""
  #     }
  #   ],
  #   "num": "01"
  # }
  def validating_chapters do
    one_piece_dir = Path.absname("library/onepiece/chapters")
    one_piece_chapter_list = Path.absname("library/onepiece/chapters.json")
    {:ok, chapters_list_data} = File.read(one_piece_chapter_list)
    {:ok, chapters_folders} = File.ls(one_piece_dir)
    {:ok, chapter_list} = Jason.decode(chapters_list_data)

    chapter_list
    |> Enum.reverse()
    |> Enum.each(fn chapter ->
      if Enum.find(chapters_folders, fn folder_name -> folder_name == chapter["num"] end) do
        IO.inspect(chapter["num"], label: "IS_FOLDER")
      else
        %{"chapters" => [chapter_info], "num" => _} = chapter
        IO.inspect(chapter["num"], label: "!IS_FOLDER")
        Crawly.fetch(chapter_info["id"], with: Spiders.MangayabuSpider)
      end
    end)
  end
end
