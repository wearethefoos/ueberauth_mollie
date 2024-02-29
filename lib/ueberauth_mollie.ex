require Logger

defmodule Ueberauth.Mollie do
  @moduledoc """
  Mollie auth strategy for `Ueberauth`.
  """
  alias OAuth2.AccessToken
  alias Ueberauth.Strategy.Mollie.OAuth

  def get(%AccessToken{} = token, path) do
    OAuth.get(token, path)
    |> handle_response()
  end

  def post(%AccessToken{} = token, path, body \\ %{}) do
    json_body = Ueberauth.json_library().encode(body)

    OAuth.post(token, path, json_body)
    |> handle_response()
  end

  def put(%AccessToken{} = token, path, body \\ %{}) do
    json_body = Ueberauth.json_library().encode(body)

    OAuth.put(token, path, json_body)
    |> handle_response()
  end

  def patch(%AccessToken{} = token, path, body \\ %{}) do
    json_body = Ueberauth.json_library().encode(body)

    OAuth.patch(token, path, json_body)
    |> handle_response()
  end

  def delete(%AccessToken{} = token, path) do
    OAuth.delete(token, path)
    |> handle_response()
  end

  defp handle_response({:ok, %OAuth2.Response{} = response}) do
    case response do
      %OAuth2.Response{status_code: 401, body: _body} ->
        {:error, :unauthorized}

      %OAuth2.Response{status_code: status_code, body: data}
      when status_code in 200..399 ->
        json_library = Ueberauth.json_library()
        {:ok, decoded_data} = json_library.decode(data)
        {:ok, decoded_data}
    end
  end

  defp handle_response({:error, %OAuth2.Error{reason: reason}}) do
    {:error, reason}
  end

  defp handle_response({:error, %OAuth2.Response{body: %{"message" => reason}}}) do
    {:error, reason}
  end

  defp handle_response({:error, err}) do
    Logger.error(err)
    {:error, :unknown}
  end
end
