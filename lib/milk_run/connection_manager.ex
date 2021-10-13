defmodule MilkRun.ConnectionManager do
  use GenServer

  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    start_watchdog()

    { :ok, state }
  end

  @impl true
  def handle_info :ensure_services_are_up, state do
    Process.send_after(self(), :ensure_services_are_up, 60_000)

    { :noreply, state
    |> ensure_bitfinex_is_connected
    |> ensure_kraken_is_connected }
  end

  @impl true
  def handle_info({ :DOWN, ref, :process, pid, reason}, state) do
    Logger.warn "#{inspect ref} is down because: #{inspect reason}, subscription #{inspect pid}"
    IO.inspect state

    {
      :noreply,
      state
      |> set_down(pid)
      |> ensure_bitfinex_is_connected
      |> ensure_kraken_is_connected
    }
  end

  defp ensure_bitfinex_is_connected %{ bitfinex: { :down, _code } } = state do
    Logger.info("Bitfinex is down, reconnecting...")
    print_time()

    MilkRun.Clients.Bitfinex.start
    |> manage_bitfinex_connection(state)
  end

  defp ensure_bitfinex_is_connected %{ bitfinex: { :up, _pid }} = state do
    state
  end

  defp ensure_bitfinex_is_connected %{ bitfinex: unknown_status } = state do
    Logger.warn("Unknown Bitfinex status in connection manager")
    print_time()
    IO.inspect unknown_status

    state
  end

  defp ensure_bitfinex_is_connected state do
    Logger.info("Initializing Bitfinex connection...")
    print_time()

    MilkRun.Clients.Bitfinex.start
    |> manage_bitfinex_connection(state)
  end

  defp ensure_kraken_is_connected %{ kraken: { :down, _code } } = state do
    Logger.warn("Kraken is down, reconnecting...")
    print_time()

    MilkRun.Clients.Kraken.start
    |> manage_kraken_connection(state)
  end

  defp ensure_kraken_is_connected %{ kraken: { :up, _pid } } = state do
    state
  end

  defp ensure_kraken_is_connected %{ kraken: unknown_status } = state do
    Logger.warn("Unknown Kraken status in connection manager")
    print_time()
    IO.inspect unknown_status

    state
  end

  defp ensure_kraken_is_connected state do
    Logger.info("Initializing Kraken connection...")
    print_time()

    MilkRun.Clients.Kraken.start
    |> manage_kraken_connection(state)
  end

  defp start_watchdog do
    send(self(), :ensure_services_are_up)
  end

  defp manage_bitfinex_connection { :ok, pid }, state do
    Logger.info "Bitfinex started: #{inspect pid}"

    Process.monitor(pid)

    state
    |> Map.put(:bitfinex, { :up, pid })
  end

  defp manage_bitfinex_connection { :error, code, message }, state do
    Logger.warn "Bitfinex error code #{code}: #{message}"

    state
    |> Map.put(:bitfinex, { :down, code })
  end

  defp manage_kraken_connection { :ok, pid }, state do
    Logger.info "Kraken started: #{inspect pid}"

    Process.monitor(pid)

    state
    |> Map.put(:kraken, { :up, pid })
  end

  defp manage_kraken_connection { :error, code, message }, state do
    Logger.warn "Kraken error code #{code}: #{message}"

    state
    |> Map.put(:kraken, { :down, code })
  end

  defp print_time do
    IO.inspect DateTime.now!("Etc/UTC")
  end

  defp set_down %{kraken: {:up, pid}} = state, pid do
    state
    |> Map.put(:kraken, {:down, 0})
  end

  defp set_down %{bitfinex: {:up, pid}} = state, pid do
    state
    |> Map.put(:bitfinex, {:down, 0})
  end
end
