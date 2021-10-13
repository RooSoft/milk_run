defmodule MilkRun.Clients.Bitfinex do
  use WebSockex
  require Logger

  alias MilkRun.Cache
  alias MilkRunWeb.Endpoint

  @stream_endpoint "wss://api.bitfinex.com/ws/1"

  @bitfinex_topic "bitfinex"
  @btcusd_message "btcusd"


  def start() do
    WebSockex.start(
      @stream_endpoint,
      __MODULE__,
      %{})
    |> manage_connection
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
    Logger.warning "Subscribing...\n#{subscription_json}"

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

    {:ok, state}
  end

  defp manage_connection { :ok, pid } do
    { :ok, pid }
  end

  defp manage_connection { :error, %WebSockex.RequestError{code: 503} } do
    { :error, 1, "Bitfinex is down"}
  end

  defp manage_connection {:error, %WebSockex.ConnError{original: :timeout}} do
    { :error, 2, "Bitfinex timeout"}
  end

  defp manage_connection { :error, error } do
    { :error, 255, "Bitfinex unknown error \n#{inspect error}"}
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

  defp maybe_broadcast(%{ status: :ok } = data, topic, message) when is_float(data.price) do
    formatted_price = :erlang.float_to_binary(data.price, [decimals: 0])
    { int_price, _ } = Integer.parse(formatted_price)

    maybe_broadcast(int_price, topic, message)
  end

  defp maybe_broadcast(%{ status: :ok } = data, topic, message) when is_integer(data.price) do
    Cache.set_btcusd(data.price)
    Endpoint.broadcast(topic, message, data.price)

    data
  end

  defp maybe_broadcast _, _, data do
    data
  end
end
