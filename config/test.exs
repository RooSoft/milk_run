import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :milk_run, MilkRunWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "HRzKpvIdiA3KSXB/fmnYakdeDhlJZf5mcaLtwHsbOwMcD6HtlT5i3rk8Xpqj9S4Y",
  server: false

# In test we don't send emails.
config :milk_run, MilkRun.Mailer,
  adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
