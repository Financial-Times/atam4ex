defmodule ATAM4Ex do
  @moduledoc """
  Supervisor to load and periodically run tests.

  # Synopsis
  ```
  opts = [period_ms: 30_000, timeout_ms: 120_000, ex_unit: [timeout: 10_000]]
  config = ATAM4Ex.init(opts)
  {:ok, pid} = ATAM4Ex.start_link(config)
  ```

  ## Options
  `ex_unit` - (`Keyword.t`) options for `ExUnit`
  `initial_delay_ms` - delay betwen starting and running the suite for the first time, default `5_000` ms
  `period_ms` - period between test suite runs, default `60_000` ms
  `timeout_ms` - timeout for entire test suite, default `60_000` ms
  `test_dir` - alternative test directory, default `test` relative to cwd.
  `server` - options for `ATAM4Ex.Web`, default `[port: 8080]`. Set to `false` to disable web-server.
  """

  require Logger

  defstruct [
    :async_cases,
    :sync_cases,
    :server,
    :initial_delay_ms,
    :period_ms,
    :timeout_ms,
    :runner_task,
    :last_result
  ]

  def init(opts \\ []) do

    {:ok, _} = Application.ensure_all_started(:yaml_elixir)

    ex_unit_init_options = ex_unit_init_options(opts)

    runner_opts = parse_opts(opts)

    {async_cases, sync_cases} = ATAM4Ex.ExUnit.init(ex_unit_init_options)

    if(length(async_cases) + length(sync_cases) == 0, do: Logger.warn(fn -> "There are no tests to run." end))

    struct(
      %__MODULE__{
        async_cases: async_cases,
        sync_cases: sync_cases,
        last_result: :too_early
      },
      runner_opts
    )
  end

  def start_link(config = %ATAM4Ex{}) do
    import Supervisor.Spec, warn: false

    web_server_spec = ATAM4Ex.Web.server_spec(config.server)

    children = web_server_spec ++ [
      supervisor(ATAM4Ex.TestSuper, [config]),
      worker(ATAM4Ex.Collector, [])
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp parse_opts(opts) do
    %{
      initial_delay_ms: opts[:initial_delay_ms] || 5000,
      period_ms: opts[:period_ms] || 60_000,
      timeout_ms: opts[:timeout_ms] || 60_000,
      server: Keyword.get(opts, :server, [port: 8080])
    }
  end

  defp ex_unit_init_options(opts) when is_list(opts) do
    ex_unit_opts = opts[:ex_unit] || []

    ex_unit_opts
    |> Keyword.merge(Keyword.take(opts, [:test_dir]))
    |> Keyword.drop([:autorun, :formatters, :capture_log])
  end

end
