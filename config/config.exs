import Config

config :ueberauth, Ueberauth.Strategy.Mollie.OAuth,
  client_id: "MOLLIE_CLIENT_ID",
  client_secret: "MOLLIE_CLIENT_SECRET",
  redirect_uri: "https://www.example.com/auth/mollie/callback"

config :ueberauth, Ueberauth,
  providers: [
    # Default is `:id`, a string in the form of `org_12345678`."
    mollie: {Ueberauth.Strategy.Mollie, [uid_field: :id]}
  ]
