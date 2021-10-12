defmodule MilkRunWeb.Live.IndexLive do
  use Phoenix.LiveView

  require Logger

  alias MilkRunWeb.Endpoint

  @bitfinex_topic "bitfinex"
  @btcusd_message "btcusd"

  @impl true
  def mount(_params, _, socket) do
    {:ok, socket
      |> get_current_value
      |> subscribe_to_events()}
  end

  @impl true
  def handle_info(%{ topic: @bitfinex_topic, event: @btcusd_message, payload: value }, socket) when is_float(value) do
    Logger.warning("Got a float #{value}")

    formatted_value = :erlang.float_to_binary(value, [decimals: 0])
    { int_value, _ } = Integer.parse(formatted_value)

    { :noreply, socket
      |> update_socket(int_value) }
  end

  @impl true
  def handle_info(%{ topic: @bitfinex_topic, event: @btcusd_message, payload: value }, socket) when is_integer(value) do
    Logger.warning("Got an integer #{value}")

    { :noreply, socket
      |> update_socket(value) }
  end

  def get_current_value(socket) do
    socket
    |> assign(:value, MilkRun.Cache.get_btcusd)
  end

  defp subscribe_to_events(socket) do
    if connected?(socket) do
      Endpoint.subscribe(@bitfinex_topic)
    end

    socket
  end

  defp update_socket socket, value do
    socket
    |> assign(:value, value)
  end

end
