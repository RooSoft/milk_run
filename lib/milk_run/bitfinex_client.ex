defmodule MilkRun.BitfinexClient do
  use WebSockex
  require Logger

  alias MilkRunWeb.Endpoint

  @stream_endpoint "wss://api.bitfinex.com/ws/1"

  @bitfinex_topic "bitfinex"
  @btcusd_message "btcusd"


  def start_link(symbol) do
    { :ok, pid } =  WebSockex.start_link(
      @stream_endpoint,
      __MODULE__,
      %{symbol: symbol})

    Logger.warning "#{inspect pid}"

    { :ok, pid }
  end


  def handle_connect(_conn, state) do
    Logger.warning "Connected to bitfinex..."

    subscription = %{
      event: "subscribe",
      channel: "ticker",
      symbol: "tBTCUSD"
    }

    subscription_json = Jason.encode!(subscription)

    WebSockex.cast(self(), {:send_message, subscription_json})

    { :ok, state }
  end

  def handle_cast({:send_message, subscription_json}, state) do
    Logger.warning "Subscribing..."

    IO.inspect subscription_json

    {:reply, { :text, subscription_json }, state}
  end

  def handle_frame({:text, message}, state) do
    Jason.decode!(message)
    |> get_price
    |> maybe_broadcast(@bitfinex_topic, @btcusd_message)

    {:ok, state}
  end

  def handle_frame({type, msg}, state) do
    Logger.warning "Received Message - Type: #{inspect type} -- Message: #{inspect msg}"

    IO.inspect type
    IO.inspect msg

    {:ok, state}
  end

  defp get_price [_channel_id, _bid, _bid_size, _ask, _ask_size, _daily_change, _daily_change_perc, last_price, volume, high, low] do
    %{
      status: :ok,
      price: last_price,
      high: high,
      low: low,
      volume: volume
    }
  end

  defp get_price _ do
    %{
      status: :nothing
    }
  end

  # defp print %{ status: :ok } = data do
  #   IO.puts data.price

  #   socket
  #   |> broadcast(@bitfinex_topic, @btcusd_message)
  # end

  # defp print %{ status: :nothing } do
  # end

  defp maybe_broadcast %{ status: :ok } = data, topic, message do
    Endpoint.broadcast(topic, message, data.price)

    data
  end

  defp maybe_broadcast _, _, data do
    data
  end
end
