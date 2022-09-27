defmodule MilkRun.Clients.Bitfinex do
  use WebSockex
  require Logger

  alias MilkRun.Cache
  alias MilkRunWeb.Endpoint

  @stream_endpoint "wss://api.bitfinex.com/ws/1"

  @btcusd_ticker_url "https://api-pub.bitfinex.com/v2/ticker/tBTCUSD"

  @bitfinex_topic "bitfinex"
  @btcusd_message "btcusd"

  def start() do
    broadcast_current_btcusd_price()

    WebSockex.start(
      @stream_endpoint,
      __MODULE__,
      %{}
    )
    |> manage_connection
  end

  def broadcast_current_btcusd_price() do
    case HTTPoison.get(@btcusd_ticker_url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        parse_current_btcusd_price!(body)
        |> broadcast(@bitfinex_topic, @btcusd_message)

        {:ok}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, 404}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def broadcast_current_btcusd_trades() do
    case HTTPoison.get(@btcusd_ticker_url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        parse_current_btcusd_price!(body)
        |> broadcast(@bitfinex_topic, @btcusd_message)

        {:ok}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, 404}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  def handle_connect(_conn, state) do
    Logger.info("Connected to Bitfinex")

    subscription = %{
      event: "subscribe",
      channel: "trades",
      symbol: "tBTCUSD"
    }

    subscription_json = Jason.encode!(subscription)

    WebSockex.cast(self(), {:send_message, subscription_json})

    {:ok, state}
  end

  def handle_cast({:send_message, subscription_json}, state) do
    Logger.debug("Bitfinex subscribing... to \n#{subscription_json}")

    {:reply, {:text, subscription_json}, state}
  end

  def handle_frame({:text, message}, state) do
    Jason.decode!(message)
    |> get_price
    |> maybe_broadcast(@bitfinex_topic, @btcusd_message)

    {:ok, state}
  end

  def handle_frame({type, msg}, state) do
    Logger.warning(
      "Received an unknown message - Type: #{inspect(type)} -- Message: #{inspect(msg)}"
    )

    {:ok, state}
  end

  defp parse_current_btcusd_price!(ticker_body) do
    [
      _bid,
      _bid_size,
      _ask,
      _ask_size,
      _daily_change,
      _daily_change_relative,
      last_price,
      _volume,
      _high,
      _low
    ] = Jason.decode!(ticker_body)

    last_price
  end

  defp manage_connection({:ok, pid}) do
    {:ok, pid}
  end

  defp manage_connection({:error, %WebSockex.RequestError{code: 503}}) do
    {:error, 1, "Bitfinex is down"}
  end

  defp manage_connection({:error, %WebSockex.ConnError{original: :timeout}}) do
    {:error, 2, "Bitfinex timeout"}
  end

  defp manage_connection({:error, error}) do
    {:error, 255, "Bitfinex unknown error \n#{inspect(error)}"}
  end

  ## trade execution
  defp get_price([_, "te", _, _amount, price, _rate]) do
    %{
      status: :ok,
      price: price
    }
  end

  ## trade update
  defp get_price([_, "tu", _, _amount, _trade_id, price, _rate]) do
    %{
      status: :ok,
      price: price
    }
  end

  defp get_price(_) do
    %{
      status: :nothing
    }
  end

  defp maybe_broadcast(%{status: :ok} = data, topic, message) when is_float(data.price) do
    formatted_price = :erlang.float_to_binary(data.price, decimals: 0)
    {int_price, _} = Integer.parse(formatted_price)

    broadcast(int_price, topic, message)
  end

  defp maybe_broadcast(%{status: :ok} = data, topic, message) when is_integer(data.price) do
    broadcast(data.price, topic, message)
  end

  defp maybe_broadcast(%{status: :nothing}, _, _) do
    # do nothing... this looks like a keepalive feature not containing any price info
  end

  defp maybe_broadcast(data, _, _) do
    Logger.warning(
      "NOT broadcasting Bitfinex BTCUSD price because of incompatible format: #{inspect(data)}"
    )
  end

  defp broadcast(price, topic, message) do
    Cache.set_btcusd(price)
    Endpoint.broadcast(topic, message, price)
  end
end
