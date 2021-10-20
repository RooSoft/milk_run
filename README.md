# MilkRun

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Production build

```bash
MIX_ENV=prod mix release
scp _build/prod/milk_run-0.x.0.tar.gz milkrun@prod-server:.
```

Then unpack the tarball wherever you like, such as `/opt/milk_run-0.x.0` and run this command

```bash
/opt/milk_run-0.x.0/bin/milk_run start
```

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
