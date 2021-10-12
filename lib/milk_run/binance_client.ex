defmodule MilkRun.BinanceClient do
  use WebSockex
  require Logger

  @stream_endpoint "wss://stream.binance.com:9443/ws/"

  def start_link(symbol) do
    { :ok, pid } =  WebSockex.start_link(
      "#{@stream_endpoint}btcusdt@trade",
      __MODULE__,
      %{symbol: symbol})

    Logger.warning "#{inspect pid}"

    { :ok, pid }
  end


  def handle_connect(_conn, state) do
    Logger.warning "Connected to binance..."

    { :ok, state }
  end

  def handle_frame({type, msg}, state) do
    Logger.warning "Received Message - Type: #{inspect type} -- Message: #{inspect msg}"

    {:ok, state}
  end
end
