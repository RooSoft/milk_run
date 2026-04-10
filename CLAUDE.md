# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

```bash
mix setup                # Install deps, build assets
mix phx.server           # Start dev server at localhost:4040
iex -S mix phx.server    # Start with interactive REPL

mix test                          # Run all tests
mix test test/path/to/file.exs    # Run single test file
mix test --failed                 # Rerun failed tests

mix format               # Format Elixir + HEEx
mix precommit            # Full validation: compile (warnings=errors), format check, deps audit, tests

mix ecto.gen.migration name  # Generate migration (always use this, never create manually)
mix ecto.migrate             # Run migrations
mix ecto.reset               # Drop + recreate + migrate + seed
```

## Architecture

Real-time crypto price monitor built with Elixir/Phoenix LiveView. Displays live BTC/USD (Bitfinex) and BTC/CAD (Kraken) prices.

### Supervision Tree

```
MilkRun.Application
├── MilkRunWeb.Telemetry
├── Phoenix.PubSub (MilkRun.PubSub)
├── MilkRunWeb.Endpoint
├── MilkRun.Cache              # GenServer: in-memory price store
├── MilkRun.Connections.Bitfinex   # GenServer: manages Bitfinex WebSocket lifecycle
└── MilkRun.Connections.Kraken     # GenServer: manages Kraken WebSocket lifecycle
```

### Data Flow

1. **Connection GenServers** (`lib/milk_run/connections/`) start WebSocket clients and fetch initial prices via REST
2. **WebSocket Clients** (`lib/milk_run/clients/`) receive trade events from exchanges via WebSockex, extract prices, store in Cache, and broadcast via PubSub
3. **IndexLive** (`lib/milk_run_web/live/index_live.ex`) subscribes to PubSub topics "bitfinex" and "kraken", updates assigns on each broadcast

Connection failures are handled via `Process.monitor` with 10-second restart delay.

### Key Modules

- `MilkRun.Cache` - GenServer holding latest btcusd/btccad prices
- `MilkRun.Connections.Connection` - Behaviour defining the connection manager interface
- `MilkRun.Clients.Bitfinex` - WebSockex client for `wss://api.bitfinex.com/ws/1`
- `MilkRun.Clients.Kraken` - WebSockex client for `wss://ws.kraken.com`
- `MilkRun.Clients.Binance` - Stub (not wired up)
- `MilkRunWeb.Live.IndexLive` - Single LiveView page at `/`

### Config

- Dev server: port 4040 (config/dev.exs)
- Prod: host `milkrun.rocks`, deployed on Fly.io (port 8080 internal)
- Assets: esbuild + Tailwind CSS with custom Google Fonts
