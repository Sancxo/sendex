import Config

config :swoosh, :api_client, Swoosh.ApiClient.Finch

config :sendex, Sendex,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: System.get_env("SENDGRID_KEY")

config :sendex,
  sender_name: System.get_env("SENDER_NAME"),
  sender_phone: System.get_env("SENDER_PHONE"),
  sender_mail: System.get_env("SENDER_MAIL"),
  reply_to: System.get_env("REPLY_TO")
