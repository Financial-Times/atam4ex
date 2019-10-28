defmodule ATAM4Ex.Router do
  @moduledoc """
  Basic router that simply forwards `/tests` to `ATAM4Ex.ATAM4JCompatiblePlug`, and
  sets categories to `:critical`.
  """

  use Plug.Router

  plug(:match)

  forward("/tests", to: ATAM4Ex.ATAM4JCompatiblePlug, init_opts: [categories: [:critical]])

  match _ do
    send_resp(conn, 404, "Not found.")
  end

  plug(:dispatch)
end
