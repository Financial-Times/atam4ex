defmodule ATAM4Ex.Web do
  @moduledoc """
  Built-in web server support.
  """

  require Logger

  @doc """
  Provide a list of Supervisor spec to start the web server.

  If `opts` is `false`, returns an empty spec list; otherwise
  returns a server spec, passing all options to `Plug.Adapters.Cowboy`,
  except:

  * `:scheme` - `:http` or `:https` chooses the plain or TLS listener.
  * `:router` - the `Plug.Router` to use, default `ATAM4Ex.Router`.
  * `:router_opts` - options passed to router's `init/1` function; default `[]`.
  """
  @spec server_spec(opts :: Keyword.t | false) :: list
  def server_spec(opts)

  def server_spec(false), do: []

  def server_spec(opts) when is_list(opts) do
    loaded = Code.ensure_loaded?(Plug.Adapters.Cowboy)
    if loaded && function_exported?(Plug.Adapters.Cowboy, :child_spec, 4) do
      {:ok, _} = Application.ensure_all_started(:plug)
      scheme = opts[:scheme] || :http
      router = opts[:router] || ATAM4Ex.Router
      router_opts = opts[:router_opts] || []
      opts = Keyword.drop(opts, [:scheme, :router, :router_opts]) # leave only adapter opts
      Logger.info(fn -> "Starting #{scheme} server on port #{opts[:port] || 4000}" end)
      [
        Plug.Adapters.Cowboy.child_spec(scheme, router, router_opts, opts)
      ]
    else
      []
    end
  end

end
