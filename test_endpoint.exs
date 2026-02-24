Mix.install([{:plug, "~> 1.14"}])
Application.ensure_all_started(:squaredle_solver)

conn =
  Plug.Test.conn(:get, "/")
  |> Plug.Conn.put_req_header("accept", "text/html")

try do
  conn = SquaredleSolverWeb.Endpoint.call(conn, [])
  IO.inspect(conn.status, label: "Status")
  IO.inspect(conn.resp_body, label: "Body")
rescue
  e -> IO.puts(Exception.format(:error, e, __STACKTRACE__))
end
