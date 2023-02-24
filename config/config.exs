import Config

config :crawly,
    fetcher: {Crawly.Fetchers.Splash, [base_url: "https://mangayabu.top/"]},
    middlewares: [
        {Crawly.Middlewares.UserAgent, user_agents: [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36"
        ]},
        Crawly.Middlewares.AutoCookiesManager
    ],
    pipelines: [
        {Crawly.Pipelines.WriteToFile, folder: "/tmp", extension: "jt"}
    ]
