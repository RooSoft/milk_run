defmodule MilkRun.Cache do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state
      |> Map.put(:btcusd, 0)
      |> Map.put(:btccad, 0)
    }
  end

  def get_btcusd() do
    GenServer.call(__MODULE__, {:get_btcusd})
  end

  def get_btccad() do
    GenServer.call(__MODULE__, {:get_btccad})
  end

  def set_btcusd(value) do
    GenServer.cast(__MODULE__, {:set_btcusd, value})
  end

  def set_btccad(value) do
    GenServer.cast(__MODULE__, {:set_btccad, value})
  end

  @impl true
  def handle_cast({:set_btcusd, value}, state) do
    {
      :noreply,
      state |> Map.put(:btcusd, value)
    }
  end

  @impl true
  def handle_cast({:set_btccad, value}, state) do
    {
      :noreply,
      state |> Map.put(:btccad, value)
    }
  end

  @impl true
  def handle_call({:get_btcusd},  _from, state) do
    { :reply, state.btcusd, state }
  end

  @impl true
  def handle_call({:get_btccad},  _from, state) do
    { :reply, state.btccad, state }
  end
end
