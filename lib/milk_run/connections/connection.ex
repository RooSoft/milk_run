defmodule MilkRun.Connections.Connection do
  @callback get_state :: :up | :starting | :down
  @callback stop :: :ok
end
