defmodule MilkRun.Cache do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(stack) do
    {:ok, stack}
  end

  def get_btcusd() do
    GenServer.call(__MODULE__, {:get_btcusd})
  end

  def set_btcusd(value) do
    GenServer.cast(__MODULE__, {:set_btcusd, value})
  end

  @impl true
  def handle_cast({:set_btcusd, value}, state) do
    {
      :noreply,
      state |> Map.put(:btcusd, value)
    }
  end

  @impl true
  def handle_call({:get_btcusd},  _from, state) do
    { :reply, state.btcusd, state }
  end
end
