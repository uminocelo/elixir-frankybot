defmodule Spiders.MangayabuSpider do
  # to run Crawly.Engine.start_spider(Spiders.MangayabuSpider)

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
    IO.inspect(response.request_url)

    case get_manga_info(response.body) do
      %{"allposts" => chapters} ->
        {:ok, _} = save_on_directory(chapters)

        %Crawly.ParsedItem{
          :items => [],
          :requests => chapters |> get_all_urls_from_json() |> create_requests_from_list(response.request_url)
        }
      %{"chapter_name" => _, "chapter_number" => _} ->
        # section table-of-contents

        %Crawly.ParsedItem{
          :items => [],
          :requests => []
        }
    end
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
    path = Path.join(library, "onepiece") |> IO.inspect()

    :ok = File.mkdir_p(path)

    path = path <> "/chapters.json" |> IO.inspect()
    File.write(path, Jason.encode!(data)) |> IO.inspect()

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
end
