defmodule Ueberauth.Strategy.Mollie do
  @moduledoc """
  Provides an Ueberauth strategy for authenticating with Mollie.

  ### Setup

  Create an application in Mollie for you to use.
  Register a new application at: [Dashboard](https://www.mollie.com/dashboard/developers/applications)
  and get the `client_id` and `client_secret`.

  Include the provider in your configuration for Ueberauth:

      config :ueberauth, Ueberauth,
        providers: [
          mollie: { Ueberauth.Strategy.Mollie, [
            scopes: "organizations.read payments.read"
          ] }
        ]

  You can use a tool like [localtunnel](https://theboroer.github.io/localtunnel-www/) to expose your local server to the internet for testing.

  Then include the configuration for Mollie:

      config :ueberauth, Ueberauth.Strategy.Mollie.OAuth,
        client_id: System.get_env("MOLLIE_CLIENT_ID"),
        client_secret: System.get_env("MOLLIE_CLIENT_SECRET"),
        redirect_uri: "https://gqgh.localtunnel.me/auth/mollie/callback" # <-- note that Mollie needs HTTPS for a callback URL scheme, even in test apps.

  If you haven't already, create a pipeline and setup routes for your callback handler

      pipeline :auth do
        Ueberauth.plug "/auth"
      end
      scope "/auth" do
        pipe_through [:browser, :auth]
        get "/:provider/callback", AuthController, :callback
      end

  Create an endpoint for the callback where you will handle the
  `Ueberauth.Auth` struct:

      defmodule MyApp.AuthController do
        use MyApp.Web, :controller
        def callback_phase(%{ assigns: %{ ueberauth_failure: fails } } = conn, _params) do
          # do things with the failure
        end
        def callback_phase(%{ assigns: %{ ueberauth_auth: auth } } = conn, params) do
          # do things with the auth
        end
      end

  You can edit the behaviour of the Strategy by including some options when you
  register your provider.

  To set the `uid_field`:

      config :ueberauth, Ueberauth,
        providers: [
          mollie: { Ueberauth.Strategy.Mollie, [uid_field: :email] } # Default is `:id`, a string in the form of `org_12345678`."
        ]

  ## Usage

  Once you obtained a token, you may use the OAuth client directly:

      Ueberauth.Strategy.Mollie.OAuth.get("/organizations/me")

  See the [Mollie API Docs](https://docs.mollie.com/index) for more information.
  """
  use Ueberauth.Strategy,
    uid_field: :id,
    default_scope: "organizations.read",
    oauth2_module: Ueberauth.Strategy.Mollie.OAuth

  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra
  alias Ueberauth.Auth.Info

  alias __MODULE__

  @doc """
  Handles the initial redirect to the Mollie authentication page.
  """
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :scope) || option(conn, :default_scope)

    params =
      [scope: scopes]
      |> with_optional(:access_type, conn)
      |> with_optional(:include_granted_scopes, conn)
      |> with_param(:access_type, conn)
      |> with_param(:prompt, conn)
      |> with_state_param(conn)

    opts = oauth_client_options_from_conn(conn)

    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [params, opts]))
  end

  @doc """
  Handles the callback from Mollie Connect.
  When there is a failure from Mollie the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from Mollie is
  returned in the `Ueberauth.Auth` struct.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    module = option(conn, :oauth2_module)
    token = apply(module, :get_token!, [[code: code]])

    if token.access_token == nil do
      set_errors!(conn, [
        error(token.other_params["error"], token.other_params["error_description"])
      ])
    else
      fetch_user(conn, token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw Mollie Connect
  response around during the callback.
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:mollie_user, nil)
    |> put_private(:mollie_token, nil)
  end

  @doc """
  Fetches the `:uid` field from the Mollie Connect response.
  This defaults to the option `:uid_field` which in-turn defaults to `:id`
  """
  def uid(conn) do
    conn |> option(:uid_field) |> to_string() |> fetch_uid(conn)
  end

  @doc """
  Includes the credentials from the Mollie Connect response.
  """
  def credentials(conn) do
    token = conn.private.mollie_token

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: true,
      scopes: String.split(token.other_params["scope"], " ", trim: true)
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth`
  struct.
  """
  def info(conn) do
    user = conn.private.mollie_user

    %Info{
      name: user["name"],
      nickname: user["name"],
      email: user["email"]
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the Mollie Connect
  callback.
  """
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.mollie_token,
        user: conn.private.mollie_user
      }
    }
  end

  defp fetch_uid(field, conn) do
    conn.private.mollie_user[field]
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :mollie_token, token)

    # Will be better with Elixir 1.3 with/else
    case Mollie.OAuth.get(token, "/organizations/me") do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])

      {:ok, %OAuth2.Response{status_code: status_code, body: user_data}}
      when status_code in 200..399 ->
        json_library = Ueberauth.json_library()
        {:ok, decoded_user_data} = json_library.decode(user_data)
        put_private(conn, :mollie_user, decoded_user_data)

      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])

      {:error, %OAuth2.Response{body: %{"message" => reason}}} ->
        set_errors!(conn, [error("OAuth2", reason)])

      {:error, _} ->
        set_errors!(conn, [error("OAuth2", "uknown error")])
    end
  end

  defp with_param(opts, key, conn) do
    if value = conn.params[to_string(key)], do: Keyword.put(opts, key, value), else: opts
  end

  defp with_optional(opts, key, conn) do
    if option(conn, key), do: Keyword.put(opts, key, option(conn, key)), else: opts
  end

  defp oauth_client_options_from_conn(conn) do
    # base_options = [redirect_uri: callback_url(conn)]
    base_options = []
    request_options = conn.private[:ueberauth_request_options].options

    case {request_options[:client_id], request_options[:client_secret]} do
      {nil, _} -> base_options
      {_, nil} -> base_options
      {id, secret} -> [client_id: id, client_secret: secret] ++ base_options
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end
end
