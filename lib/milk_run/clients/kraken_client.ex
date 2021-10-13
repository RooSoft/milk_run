defmodule MilkRun.Clients.Kraken do
  use WebSockex
  require Logger

  @stream_endpoint "wss://ws.kraken.com"

  alias MilkRun.Cache
  alias MilkRunWeb.Endpoint

  @kraken_topic "kraken"
  @btccad_message "btccad"


  def start_link(_) do
    { :ok, pid } =  WebSockex.start_link(
      @stream_endpoint,
      __MODULE__,
      %{})

    Logger.warning "#{inspect pid}"

    { :ok, pid }
  end


  def handle_connect(_conn, state) do
    Logger.warning "Connected to kraken..."

    subscription = %{
      event: "subscribe",
      pair: ["BTC/CAD"],
      subscription: %{
        name: "trade"
      }
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
    message
    |> Jason.decode!
    |> process

    {:ok, state}
  end

  defp process %{ "event" => "heartbeat" } do
    IO.puts "Heartbeat"
  end

  defp process([_channel_id, trades, "trade", "XBT/CAD"]) when is_list(trades) do
    [price_string, volume_string, _time, _side, _order_type, _misc] = trades |> List.last

    {price, _} = price_string |> Float.parse
    {volume, _} = volume_string |> Float.parse

    IO.puts "New BTC/CAD price of #{price}. #{volume} coins has been traded."

    price |> broadcast(@kraken_topic, @btccad_message)
  end

  defp process message do
    IO.puts "Unknown packet"
    IO.inspect message
  end

  defp broadcast(price, topic, message) do
    Cache.set_btccad(price)
    Endpoint.broadcast(topic, message, price)

    price
  end
end
