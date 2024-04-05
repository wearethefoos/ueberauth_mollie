defmodule Mollie.Client do
  @moduledoc """
  Mollie API client

  Add the following to your `config.exs` file:

      config :ueberauth, Ueberauth.Mollie,
        api_key: "your_api_key"
  """

  def new(api_key \\ nil) do
    token = api_key || config()[:api_key]

    middleware =
      [
        {Tesla.Middleware.BaseUrl, "https://api.mollie.com/v2"},
        {Tesla.Middleware.BearerAuth, token: token},
        Tesla.Middleware.JSON
      ]

    Tesla.client(middleware)
  end

  def config do
    Application.get_env(:ueberauth, Ueberauth.Mollie)
  end
end
