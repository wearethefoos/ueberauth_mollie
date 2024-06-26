require Logger

defmodule Ueberauth.Strategy.Mollie.OAuth do
  @moduledoc """
  An implementation of OAuth2 for Mollie.
  To add your `:client_id` and `:client_secret` include these values in your
  configuration:
      config :ueberauth, Ueberauth.Strategy.Mollie.OAuth,
        client_id: System.get_env("MOLLIE_CLIENT_ID"),
        client_secret: System.get_env("MOLLIE_CLIENT_SECRET"),
        redirect_uri: "https://example.com/auth/mollie/callback"
  """
  use OAuth2.Strategy

  alias Ueberauth.Strategy.Mollie

  @defaults [
    strategy: __MODULE__,
    site: "https://api.mollie.com/v2",
    authorize_url: "https://my.mollie.com/oauth2/authorize",
    token_url: "https://api.mollie.com/oauth2/tokens",
    token_method: :post
  ]

  @doc """
  Construct a client for requests to Mollie.
  Optionally include any OAuth2 options here to be merged with the defaults:
      Ueberauth.Strategy.Mollie.OAuth.client(
        redirect_uri: "http://localhost:4000/auth/mollie/callback"
      )
  This will be setup automatically for you in `Ueberauth.Strategy.Mollie`.
  These options are only useful for usage outside the normal callback phase of
  Ueberauth.
  """
  def client(opts \\ []) do
    config =
      :ueberauth
      |> Application.fetch_env!(Mollie.OAuth)
      |> check_credential(:client_id)
      |> check_credential(:client_secret)

    json_library = Ueberauth.json_library()

    @defaults
    |> Keyword.merge(config)
    |> Keyword.merge(opts)
    |> OAuth2.Client.new()
    |> OAuth2.Client.put_serializer("application/json", json_library)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth.
  No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.authorize_url!(params)
  end

  def get(token, url, headers \\ [], opts \\ []) do
    [token: token]
    |> client
    |> put_param("client_secret", client().client_secret)
    |> OAuth2.Client.get(url, headers, opts)
  end

  def post(token, url, body \\ "", headers \\ [], opts \\ []) do
    [token: token]
    |> client
    |> put_param("client_secret", client().client_secret)
    |> OAuth2.Client.post(url, body, headers, opts)
  end

  def put(token, url, body \\ "", headers \\ [], opts \\ []) do
    [token: token]
    |> client
    |> put_param("client_secret", client().client_secret)
    |> OAuth2.Client.put(url, body, headers, opts)
  end

  def patch(token, url, body \\ "", headers \\ [], opts \\ []) do
    [token: token]
    |> client
    |> put_param("client_secret", client().client_secret)
    |> OAuth2.Client.patch(url, body, headers, opts)
  end

  def delete(token, url, headers \\ [], opts \\ []) do
    [token: token]
    |> client
    |> put_param("client_secret", client().client_secret)
    |> OAuth2.Client.delete(url, headers, opts)
  end

  def get_access_token(params \\ [], opts \\ []) do
    case opts |> client |> OAuth2.Client.get_token(params) do
      {:error, %OAuth2.Response{body: %{"error" => error}} = response} ->
        description = Map.get(response.body, "error_description", "")
        {:error, {error, description}}

      {:error, %OAuth2.Error{reason: reason}} ->
        {:error, {"error", to_string(reason)}}

      {:ok, %OAuth2.Client{token: token}} ->
        {:ok, token}
    end
  end

  def get_token!(params \\ [], options \\ []) do
    headers = Keyword.get(options, :headers, [])
    options = Keyword.get(options, :options, [])
    client_options = Keyword.get(options, :client_options, [])
    client = OAuth2.Client.get_token!(client(client_options), params, headers, options)
    client.token
  end

  def refresh_auth_token!(token, params \\ [], options \\ []) do
    headers = Keyword.get(options, :headers, [])
    options = Keyword.get(options, :options, [])
    client_options = Keyword.get(options, :client_options, token: token)

    case OAuth2.Client.refresh_token(client(client_options), params, headers, options) do
      {:ok, response} -> {:ok, response.token}
      {:error, error} -> {:error, error}
    end
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    Mollie.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param("client_secret", client.client_secret)
    |> put_header("Accept", "application/json")
    |> Mollie.AuthCode.get_token(params, headers)
  end

  def refresh_auth_token(client, params, headers) do
    client
    |> put_param("client_secret", client.client_secret)
    |> put_header("Accept", "application/json")
    |> Mollie.AuthCode.refresh_auth_token(params, headers)
  end

  defp check_credential(config, key) do
    check_config_key_exists(config, key)

    case Keyword.get(config, key) do
      value when is_binary(value) ->
        config

      {:system, env_key} ->
        case System.get_env(env_key) do
          nil ->
            raise "#{inspect(env_key)} missing from environment, expected in config :ueberauth, Ueberauth.Strategy.Mollie"

          value ->
            Keyword.put(config, key, value)
        end
    end
  end

  defp check_config_key_exists(config, key) when is_list(config) do
    unless Keyword.has_key?(config, key) do
      raise "#{inspect(key)} missing from config :ueberauth, Ueberauth.Strategy.Mollie"
    end

    config
  end

  defp check_config_key_exists(_, _) do
    raise "Config :ueberauth, Ueberauth.Strategy.Mollie is not a keyword list, as expected"
  end

  @spec parse_response(
          {:ok, OAuth2.Response.t()}
          | {:error, OAuth2.Response.t()}
          | {:error, OAuth2.Error.t()}
        ) :: {:ok, map()} | {:error, :unauthorized | :unexpected_response | :unknown | binary()}
  def parse_response({:ok, %OAuth2.Response{status_code: 401, body: _body}}) do
    {:error, :unauthorized}
  end

  def parse_response({:ok, %OAuth2.Response{status_code: status_code, body: data}})
      when status_code in 200..399 do
    json_library = Ueberauth.json_library()
    {:ok, decoded_data} = json_library.decode(data)
    {:ok, decoded_data}
  end

  def parse_response({:ok, %OAuth2.Response{status_code: status_code, body: data}}) do
    Logger.error("Unexpected response: #{status_code} - #{data}")
    {:error, :unexpected_response}
  end

  def parse_response({:error, %OAuth2.Error{reason: reason}}) do
    {:error, reason}
  end

  def parse_response({:error, %OAuth2.Response{body: %{"message" => reason}}}) do
    {:error, reason}
  end

  def parse_response({:error, err}) do
    Logger.error(err)
    {:error, :unknown}
  end
end
