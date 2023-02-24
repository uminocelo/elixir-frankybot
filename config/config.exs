import Config

config :crawly,
    fetcher: {Crawly.Fetchers.Splash, [base_url: "http://localhost:8050/render.html"]},
    middlewares: [
        Crawly.Middlewares.DomainFilter,
        Crawly.Middlewares.UniqueRequest,
        {Crawly.Middlewares.UserAgent, user_agents: [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36"
        ]},
        Crawly.Middlewares.AutoCookiesManager,
        {Crawly.Middlewares.RequestOptions, [timeout: 30_000, recv_timeout: 15000]}
    ],
    pipelines: [
        {Crawly.Pipelines.WriteToFile, folder: "/tmp", extension: "csv"}
    ],
    retry:
    [
      retry_codes: [400],
      max_retries: 3
    ]
