defmodule MilkRunWeb.PageController do
  use MilkRunWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
