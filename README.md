# UeberauthMollie

> Ueberauth Strategy for [Mollie](https://www.mollie.com/).

## Installation

The package can be installed by adding `ueberauth_mollie` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ueberauth_mollie, "~> 0.1.0"}
  ]
end
```

Add the Strategy to your Ueberauth strategies:

```elixir
# config/config.exs
config :ueberauth, Ueberauth,
  providers: [
    mollie: {Ueberauth.Strategy.Mollie, []}
  ]
```

## Configuration

Start by registering your own Mollie Apps in the [Dashboard](https://www.mollie.com/dashboard/developers/applications).

Use a tool like [localtunnel](https://theboroer.github.io/localtunnel-www/) to expose your local development environment to the internet.

Create two new apps (one for dev and one for prod) and set the redirect URL to `https://gqgh.localtunnel.me/auth/mollie/callback` for development, and `https://example.com/auth/mollie/callback` for production.

> Take note of the Client ID and Client Secret, as you will need them for the next steps.

### Development

Configure your dev env:

```elixir
# config/dev.exs
config :ueberauth, Ueberauth.Strategy.Mollie.OAuth,
  client_id: "app_123456",
  client_secret: "abcd123456",
  redirect_uri: "https://gqgh.localtunnel.me/auth/mollie/callback" # <-- note that Mollie needs HTTPS for a callback URL scheme, even in test apps.
```

### Production

Configure your prod env:

```elixir
# config/prod.exs
config :ueberauth, Ueberauth.Strategy.Mollie.OAuth,
  client_id: System.get_env("MOLLIE_CLIENT_ID"),
  client_secret: System.get_env("MOLLIE_CLIENT_SECRET"),
  redirect_uri: "https://example.com/auth/mollie/callback"
```

## Usage

Once you obtained a token, you may use the OAuth client directly:

```elixir
Ueberauth.Strategy.Mollie.OAuth.get("/organizations/me")
```

See the [Mollie API Docs](https://docs.mollie.com/index) for more information. Note that the provided client knows about the `/v2` prefix already.

## Further Docs

Check out the [documentation](https://hexdocs.pm/ueberauth_mollie). And specifically the `Ueberauth.Strategy.Mollie` module.

## Disclaimer

This library is in no way related to or supported by the company or team behind Mollie.
