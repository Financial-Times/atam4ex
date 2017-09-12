defmodule ATAM4Ex.Router do
  use Plug.Router

  plug :match

  forward "/tests", to: ATAM4Ex.ATAM4JCompatiblePlug, init_opts: [categories: [:critical]]

  match _ do
    send_resp(conn, 404, "Not found.")
  end

  plug :dispatch
end
