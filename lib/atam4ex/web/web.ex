defmodule ATAM4Ex.Web do
  @moduledoc """
  Built-in web server support.
  """

  require Logger

  @doc """
  Provide a list of Supervisor spec that can be used to start the web server.

  This is just a wrapper around Cowboy for the convenience of
  starting the default ATAM4Ex server:

  ```elixir
  opts = [port: 8081]
  children = ATAM4Ex.Web.server_spec(opts)
  Supervisor.start_link(children, strategy: :one_for_one)
  ```

  If `opts` is `false`, returns an empty spec list (i.e. it won't start the
  web server); otherwise returns a list of child spec, passing all options to
  [Plug.Cowboy](https://github.com/elixir-plug/plug_cowboy#supervised-handlers),
  after interpreting and dropping:

  * `:scheme` - `:http` or `:https` chooses the plain or TLS listener.
  * `:router` - the `Plug.Router` to use, default `ATAM4Ex.Router`.
  * `:router_opts` - options passed to router's `init/1` function; default `[]`.
  """
  @spec server_spec(opts :: Keyword.t() | false) :: list
  def server_spec(opts)

  def server_spec(false), do: []

  def server_spec(opts) when is_list(opts) do
    loaded = Code.ensure_loaded?(Plug.Cowboy)

    if loaded && function_exported?(Plug.Cowboy, :child_spec, 1) do
      {:ok, _} = Application.ensure_all_started(:plug_cowboy)
      scheme = opts[:scheme] || :http
      router = opts[:router] || ATAM4Ex.Router
      router_opts = opts[:router_opts] || []
      # leave only adapter opts
      cowboy_opts = Keyword.drop(opts, [:scheme, :router, :router_opts])
      Logger.info(fn -> "Starting #{scheme} server on port #{opts[:port] || 4000}" end)

      [
        Plug.Cowboy.child_spec(scheme: scheme, plug: {router, router_opts}, options: cowboy_opts)
      ]
    else
      []
    end
  end
end
