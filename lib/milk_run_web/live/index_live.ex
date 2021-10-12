defmodule MilkRunWeb.Live.IndexLive do
  # If you generated an app with mix phx.new --live,
  # the line below would be: use MyAppWeb, :live_view
  use Phoenix.LiveView

  def mount(_params, _, socket) do
    {:ok, socket}
  end
end
