defmodule MilkRunWeb.Live.IndexLive do
  use Phoenix.LiveView

  alias MilkRunWeb.Endpoint

  @bitfinex_topic "bitfinex"
  @btcusd_message "btcusd"

  @impl true
  def mount(_params, _, socket) do
    {:ok, socket
      |> init_value
      |> subscribe_to_events()}
  end

  @impl true
  def handle_info(%{ topic: @bitfinex_topic, event: @btcusd_message, payload: value }, socket) do
    IO.inspect value

    socket = socket
      |> update_socket(value)

    { :noreply, socket }
  end

  def init_value(socket) do
    socket
    |> assign(:value, "N/D")
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
