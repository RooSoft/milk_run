defmodule MilkRun.Connections.Bitfinex do
  use GenServer

  require Logger

  alias MilkRun.Connections.Connection

  @behaviour Connection

  @restart_delay 10000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{state: :down}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    Logger.info("#{DateTime.now!("Etc/UTC")}: Initializing bitfinex connection", ansi_color: :light_blue)

    Process.send(__MODULE__, {:start}, [])

    { :ok, state }
  end

  @impl Connection
  def stop do
    Logger.info("#{DateTime.now!("Etc/UTC")}: Manually stopping bitfinex connection", ansi_color: :light_blue)

    GenServer.stop(__MODULE__, :manual)
  end

  @impl Connection
  def get_state do
    GenServer.call(__MODULE__, {:get_state})
  end

  @impl true
  def handle_info({:start}, state) do
    Logger.info "#{DateTime.now!("Etc/UTC")}: Starting bitfinex connection", ansi_color: :light_blue

    {
      :noreply,
      MilkRun.Clients.Bitfinex.start
      |> manage_connection(state)
    }
  end

  @impl true
  def handle_info({ :DOWN, ref, :process, pid, reason}, state) do
    Logger.warn "#{inspect pid} #{inspect ref} is down because: #{inspect reason}"
    Logger.warn "Will restart in #{@restart_delay/1000}s"

    # try to restart the service after a given delay
    Process.send_after(self(), :start, @restart_delay)

    { :noreply, %{ state | state: :down } }
  end

  @impl true
  def handle_call({:get_state},  _from, state) do
    { :reply, state.state, state }
  end


  defp manage_connection { :ok, pid }, state do
    Logger.info "#{DateTime.now!("Etc/UTC")}: Bitfinex started: #{inspect pid}", ansi_color: :light_blue

    Process.monitor(pid)

    %{ state | state: :up }
  end

  defp manage_connection { :error, code, message }, state do
    Logger.warn "Bitfinex issued an error #{code} on startup : #{message}"

    %{ state | state: :down }
  end
end
