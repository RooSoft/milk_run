defmodule MilkRunWeb.Live.IndexLive do
  use Phoenix.LiveView

  require Logger

  alias MilkRunWeb.Endpoint

  @bitfinex_topic "bitfinex"
  @kraken_topic "kraken"

  @btcusd_message "btcusd"
  @btccad_message "btccad"

  @impl true
  def mount(_params, _, socket) do
    {:ok, socket
      |> get_current_values
      |> subscribe_to_events()}
  end

  @impl true
  def handle_info(%{ topic: @bitfinex_topic, event: @btcusd_message, payload: value }, socket) when is_float(value) do
    Logger.warning("Got a bitfinex float #{value}")

    formatted_value = :erlang.float_to_binary(value, [decimals: 0])
    { int_value, _ } = Integer.parse(formatted_value)

    { :noreply, socket
      |> update_btcusd(int_value) }
  end

  @impl true
  def handle_info(%{ topic: @bitfinex_topic, event: @btcusd_message, payload: value }, socket) when is_integer(value) do
    Logger.warning("Got a bitfinex integer #{value}")

    { :noreply, socket
      |> update_btcusd(value) }
  end

  @impl true
  def handle_info(%{ topic: @kraken_topic, event: @btccad_message, payload: value }, socket) when is_float(value) do
    Logger.warning("Got a kraken float #{value}")

    { :noreply, socket
      |> update_btccad(value) }
  end

  def get_current_values(socket) do
    socket
    |> assign(:btcusd, MilkRun.Cache.get_btcusd)
    |> assign(:btccad, MilkRun.Cache.get_btccad)
  end

  defp subscribe_to_events(socket) do
    if connected?(socket) do
      Endpoint.subscribe(@bitfinex_topic)
      Endpoint.subscribe(@kraken_topic)
    end

    socket
  end

  defp update_btcusd socket, value do
    socket
    |> assign(:btcusd, value)
  end

  defp update_btccad socket, value do
    socket
    |> assign(:btccad, value)
  end

end
