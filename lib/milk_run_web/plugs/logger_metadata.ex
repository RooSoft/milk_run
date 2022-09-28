defmodule MilkRunWeb.Plugs.SetLoggerMetadata do
  def init(opts), do: opts

  def call(conn, _opts) do
    remote_ip = format_ip(conn)

    Logger.metadata(remote_ip: remote_ip)

    conn
  end

  defp format_ip(%{remote_ip: nil}), do: nil

  defp format_ip(%{remote_ip: remote_ip}) do
    :inet_parse.ntoa(remote_ip)
    |> to_string
  end
end
