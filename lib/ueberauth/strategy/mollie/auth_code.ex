defmodule Ueberauth.Strategy.Mollie.AuthCode do
  @moduledoc """
  The Authorization Code Strategy.

  http://tools.ietf.org/html/rfc6749#section-1.3.1

  The authorization code is obtained by using an authorization server
  as an intermediary between the client and resource owner.  Instead of
  requesting authorization directly from the resource owner, the client
  directs the resource owner to an authorization server (via its
  user-agent as defined in [RFC2616]), which in turn directs the
  resource owner back to the client with the authorization code.

  Before directing the resource owner back to the client with the
  authorization code, the authorization server authenticates the
  resource owner and obtains authorization.  Because the resource owner
  only authenticates with the authorization server, the resource
  owner's credentials are never shared with the client.

  The authorization code provides a few important security benefits,
  such as the ability to authenticate the client, as well as the
  transmission of the access token directly to the client without
  passing it through the resource owner's user-agent and potentially
  exposing it to others, including the resource owner.
  """

  use OAuth2.Strategy

  @doc """
  The authorization URL endpoint of the provider.
  params additional query parameters for the URL
  """
  @impl true
  def authorize_url(client, params) do
    client
    |> put_param(:response_type, "code")
    |> put_param(:client_id, client.client_id)
    |> put_param(:redirect_uri, client.redirect_uri)
    |> merge_params(params)
  end

  @doc """
  Retrieve an access token given the specified validation code.
  """
  @impl true
  def get_token(client, params, headers) do
    {code, params} = Keyword.pop(params, :code, client.params["code"])

    unless code do
      raise OAuth2.Error, reason: "Missing required key `code` for `#{inspect(__MODULE__)}`"
    end

    client
    |> put_param(:code, code)
    |> put_param(:grant_type, "authorization_code")
    |> put_param(:client_id, client.client_id)
    |> put_param(:redirect_uri, client.redirect_uri)
    |> merge_params(params)
    |> put_headers(headers)
  end

  def refresh_auth_token(client, params, headers) do
    {refresh_token, params} = Keyword.pop(params, :refresh_token, client.params["refresh_token"])

    unless refresh_token do
      raise OAuth2.Error,
        reason: "Missing required key `refresh_token` for `#{inspect(__MODULE__)}`"
    end

    client
    |> put_param(:refresh_token, refresh_token)
    |> put_param(:grant_type, "refresh_token")
    |> put_param(:client_id, client.client_id)
    |> merge_params(params)
    |> put_headers(headers)
  end
end
