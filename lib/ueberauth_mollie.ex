require Logger

defmodule UeberauthMollie do
  @moduledoc """
  Mollie auth strategy for `Ueberauth`.
  """
  alias OAuth2.AccessToken
  alias Ueberauth.Strategy.Mollie

  @spec get(OAuth2.AccessToken.t(), binary()) ::
          {:ok, map()} | {:error, :unauthorized | :unexpected_response | :unknown | binary()}
  def get(%AccessToken{} = token, path) do
    Mollie.OAuth.get(token, path)
    |> response()
  end

  @spec post(OAuth2.AccessToken.t(), binary()) ::
          {:ok, map()} | {:error, :unauthorized | :unexpected_response | :unknown | binary()}
  def post(%AccessToken{} = token, path, body \\ %{}) do
    json_body = Ueberauth.json_library().encode!(body)

    Mollie.OAuth.post(token, path, json_body)
    |> response()
  end

  @spec put(OAuth2.AccessToken.t(), binary()) ::
          {:ok, map()} | {:error, :unauthorized | :unexpected_response | :unknown | binary()}
  def put(%AccessToken{} = token, path, body \\ %{}) do
    json_body = Ueberauth.json_library().encode!(body)

    Mollie.OAuth.put(token, path, json_body)
    |> response()
  end

  @spec patch(OAuth2.AccessToken.t(), binary()) ::
          {:ok, map()} | {:error, :unauthorized | :unexpected_response | :unknown | binary()}
  def patch(%AccessToken{} = token, path, body \\ %{}) do
    json_body = Ueberauth.json_library().encode!(body)

    Mollie.OAuth.patch(token, path, json_body)
    |> response()
  end

  @spec delete(OAuth2.AccessToken.t(), binary()) ::
          {:ok, map()} | {:error, :unauthorized | :unexpected_response | :unknown | binary()}
  def delete(%AccessToken{} = token, path) do
    Mollie.OAuth.delete(token, path)
    |> response()
  end

  def response(resp), do: Mollie.OAuth.parse_response(resp)
end
