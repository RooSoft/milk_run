defmodule MilkRunWeb.Plugs.ClientIp do
  require Logger
  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _opts) do
    Logger.metadata(client_ip: get_ip(conn))
    conn
  end

  # This code is from Plausible Analytics https://github.com/plausible/analytics/blob/3a1c9e67cd67d5cb1fec68a4dee34f8cd0e056fd/lib/plausible_web/remote_ip.ex
  defp get_ip(conn) do
    forwarded_for = List.first(Plug.Conn.get_req_header(conn, "x-forwarded-for"))

    if forwarded_for do
      String.split(forwarded_for, ",")
      |> Enum.map(&String.trim/1)
      |> List.first()
    else
      to_string(:inet_parse.ntoa(conn.remote_ip))
    end
  end
end
