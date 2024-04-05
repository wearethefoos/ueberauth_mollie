defmodule Ueberauth.Strategy.MollieTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import Mock
  import Plug.Conn
  import Ueberauth.Strategy.Helpers

  setup_with_mocks([
    {OAuth2.Client, [:passthrough],
     [
       get_token: &oauth2_get_token/2,
       get: &oauth2_get/4
     ]}
  ]) do
    # Create a connection with Ueberauth's CSRF cookies so they can be recycled during tests
    routes = Ueberauth.init([])
    csrf_conn = conn(:get, "/auth/mollie", %{}) |> Ueberauth.call(routes)
    csrf_state = with_state_param([], csrf_conn) |> Keyword.get(:state)

    {:ok, csrf_conn: csrf_conn, csrf_state: csrf_state}
  end

  def set_options(routes, conn, opt) do
    case Enum.find_index(routes, &(elem(&1, 0) == {conn.request_path, conn.method})) do
      nil ->
        routes

      idx ->
        update_in(routes, [Access.at(idx), Access.elem(1), Access.elem(2)], &%{&1 | options: opt})
    end
  end

  defp token(client, access_token),
    do:
      {:ok,
       %{
         client
         | token:
             OAuth2.AccessToken.new(%{
               "access_token" => access_token,
               "scope" => "organizations.read"
             })
       }}

  defp response(body, code \\ 200), do: {:ok, %OAuth2.Response{status_code: code, body: body}}

  def oauth2_get_token(client, code: "success_code"), do: token(client, "success_token")
  def oauth2_get_token(client, code: "uid_code"), do: token(client, "uid_token")
  def oauth2_get_token(client, code: "userinfo_code"), do: token(client, "userinfo_token")

  def oauth2_get_token(_client, code: "oauth2_error"),
    do: {:error, %OAuth2.Error{reason: :timeout}}

  def oauth2_get_token(_client, code: "error_response"),
    do:
      {:error,
       %OAuth2.Response{
         body: %{"error" => "some error", "error_description" => "something went wrong"}
       }}

  def oauth2_get_token(_client, code: "error_response_no_description"),
    do: {:error, %OAuth2.Response{body: %{"error" => "internal_failure"}}}

  def oauth2_get(%{token: %{access_token: "success_token"}}, _url, _, _),
    do:
      response(
        Jason.encode!(%{
          "resource" => "organization",
          "id" => "org_12345678",
          "name" => "Mollie B.V.",
          "email" => "info@mollie.com",
          "address" => %{
            "streetAndNumber" => "Keizersgracht 126",
            "postalCode" => "1015 CW",
            "city" => "Amsterdam",
            "country" => "NL"
          },
          "registrationNumber" => "30204462",
          "vatNumber" => "NL815839091B01",
          "_links" => %{}
        })
      )

  def oauth2_get(%{token: %{access_token: "uid_token"}}, _url, _, _),
    do: response(%{"uid_field" => "1234_daphne", "name" => "Daphne Blake"})

  def oauth2_get(
        %{token: %{access_token: "userinfo_token"}},
        "https://api.mollie.com/v2/organizations/me",
        _,
        _
      ),
      do: response(%{"sub" => "1234_velma", "name" => "Velma Dinkley"})

  def oauth2_get(%{token: %{access_token: "userinfo_token"}}, "example.com/shaggy", _, _),
    do: response(%{"sub" => "1234_shaggy", "name" => "Norville Rogers"})

  def oauth2_get(%{token: %{access_token: "userinfo_token"}}, "example.com/scooby", _, _),
    do: response(%{"sub" => "1234_scooby", "name" => "Scooby Doo"})

  defp set_csrf_cookies(conn, csrf_conn) do
    conn
    |> init_test_session(%{})
    |> recycle_cookies(csrf_conn)
    |> fetch_cookies()
  end

  test "handle_request! redirects to appropriate auth uri" do
    conn = conn(:get, "/auth/mollie", %{})
    # Make sure the hd and scope params are included for good measure
    routes = Ueberauth.init() |> set_options(conn, default_scope: "organizations.read")

    resp = Ueberauth.call(conn, routes)

    assert resp.status == 302
    assert [location] = get_resp_header(resp, "location")

    redirect_uri = URI.parse(location)
    assert redirect_uri.host == "my.mollie.com"
    assert redirect_uri.path == "/oauth2/authorize"

    assert %{
             "client_id" => "MOLLIE_CLIENT_ID",
             "redirect_uri" => "https://www.example.com/auth/mollie/callback",
             "response_type" => "code",
             "scope" => "organizations.read",
             "state" => csrf_state
           } = Plug.Conn.Query.decode(redirect_uri.query)

    assert is_nil(csrf_state) == false
  end

  test "handle_callback! assigns required fields on successful auth", %{
    csrf_state: csrf_state,
    csrf_conn: csrf_conn
  } do
    conn =
      conn(:get, "/auth/mollie/callback", %{
        code: "success_code",
        state: csrf_state
      })
      |> set_csrf_cookies(csrf_conn)

    routes = Ueberauth.init([])
    assert %Plug.Conn{assigns: %{ueberauth_auth: auth}} = Ueberauth.call(conn, routes)
    assert auth.credentials.token == "success_token"
    assert auth.info.name == "Mollie B.V."
    assert auth.info.email == "info@mollie.com"
    assert auth.uid == "org_12345678"
  end
end
