defmodule FrankyBot do
  @moduledoc """
  Documentation for `FrankyBot`.
  """

  @manga_web_site "https://mangayabu.top/manga/one-piece/"
  @manga_main_page "./lib/main.html"
  @doc """
  Verifica se o web site está online!

  ## Examples

      iex> FrankyBot.checking_availability()
      "Tudo certo! Suuuuuuuuuper! :star:"

  """
  def checking_availability do
    HTTPoison.get!(@manga_web_site)
    |> case do
      %{status_code: 200, body: body} ->
        {:ok, body}

      %{body: body} ->
        {:error, body}
    end
  end

  # script defer id="manga-info"
  # def parse_main_page do
  #   with {:ok, body} <- checking_availability() do
  #     {:ok, html_parsed} = Floki.parse_document(body)
  #     IO.puts(inspect(html_parsed))
  #     Floki.attribute(html_parsed, "script[defer=defer]", "id=manga-info")
  #   end
  # end

  def test do
    {:ok, content} = File.read(@manga_main_page)
    {:ok, html_parsed} = Floki.parse_document(content)

    response =
      Floki.find(html_parsed, "script[id=manga-info]")
      |> Floki.raw_html(encode: false, pretty: true)

    %{"allposts" => posts} =
      String.replace(
        response,
        "<script defer=\"defer\" id=\"manga-info\" type=\"application\/json\">",
        ""
      )
      |> String.replace("</script>", "")
      |> String.trim()
      |> Jason.decode!()

    posts
  end
end
