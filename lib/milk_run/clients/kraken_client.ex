defmodule MilkRun.Clients.Kraken do
  use WebSockex
  require Logger

  alias MilkRun.Cache
  alias MilkRunWeb.Endpoint

  @stream_endpoint "wss://ws.kraken.com"

  @btccad_ticker_url "https://api.kraken.com/0/public/Ticker?pair=XBTCAD"

  @kraken_topic "kraken"
  @btccad_message "btccad"


  def start() do
    broadcast_current_btccad_price()

    WebSockex.start(
      @stream_endpoint,
      __MODULE__,
      %{})
    |> manage_connection
  end

  def broadcast_current_btccad_price() do
    case HTTPoison.get(@btccad_ticker_url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        parse_current_btccad_price!(body)
        |> broadcast(@kraken_topic, @btccad_message)

        {:ok}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, 404}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end


  def handle_connect(_conn, state) do
    Logger.info "Connected to kraken..."

    subscription = Jason.encode!(%{
      event: "subscribe",
      pair: ["BTC/CAD"],
      subscription: %{
        name: "trade"
      }
    })

    WebSockex.cast(self(), {:send_message, subscription})

    { :ok, state }
  end

  def handle_cast({:send_message, subscription_json}, state) do
    Logger.info "Subscribing to Kraken..."

    {:reply, { :text, subscription_json }, state}
  end

  def handle_frame({:text, message}, state) do
    message
    |> Jason.decode!
    |> process

    {:ok, state}
  end


  defp parse_current_btccad_price! ticker_body do
    %{
      "result" => %{
        "XXBTZCAD" => %{ "c" => [price_string, _volume] }
      }
    } = Jason.decode!(ticker_body)

    {price, _} = price_string |> Float.parse

    price
  end

  defp manage_connection { :ok, pid } do
    { :ok, pid }
  end

  defp manage_connection { :error, %WebSockex.RequestError{code: 503} } do
    { :error, 1, "Kraken is down"}
  end

  defp manage_connection { :error, %WebSockex.ConnError{original: :econnrefused} } do
    { :error, 2, "Kraken connection is refused"}
  end

  defp manage_connection { :error, error } do
    { :error, 255, "Kraken unknown error\n#{inspect error}"}
  end

  defp process %{ "event" => "heartbeat" } do
     # nothing to do here, heatbeats usually being sent every second or so
  end

  defp process([_channel_id, trades, "trade", "XBT/CAD"]) when is_list(trades) do
    [price_string, _volume_string, _time, _side, _order_type, _misc] = trades |> List.last

    {price, _} = price_string |> Float.parse

    price |> broadcast(@kraken_topic, @btccad_message)
  end

  defp process %{ "channelName" => "trade", "pair" => "XBT/CAD", "status" => "subscribed", "subscription" => %{"name" => "trade"} } do
    Logger.info "Successfully connected to Kraken XBT/CAD trades websocket"
  end

  defp process %{"connectionID" => _connection_id, "event" => "systemStatus", "status" => "online", "version" => _version} do
    Logger.info "Kraken is online"
  end

  defp process message do
    Logger.warning "Unknown packet"
    Logger.warning inspect message
  end

  defp broadcast(price, topic, message) do
    Cache.set_btccad(price)
    Endpoint.broadcast(topic, message, price)

    price
  end
end
