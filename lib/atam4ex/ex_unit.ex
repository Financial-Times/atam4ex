defmodule ATAM4Ex.ExUnit do
  @moduledoc """
  Integration with `ExUnit.
  """

  @type summary :: %{
          duration_us: non_neg_integer,
          failures: non_neg_integer,
          skipped: non_neg_integer,
          total: non_neg_integer
        }

  @doc """
  Dynamically require tests from `*_test.exs` files and return tuple with async and sync tests

  Must be run before `ExUnit.start()`.

  ## Parameters
  `opts` - Keyword list of options:
  * test_dir - directory to load tests from, default "test".

  For other options, see `ExUnit.configure/1`; not that `autorun`,
  `capture_log` and `formatters` are not settable, since these
  are required for ATAM4Ex to work.

  """
  @spec init(opts :: Keyword.t()) :: {async_modules :: [module], sync_modules :: [module]}
  def init(opts) do
    opts =
      Keyword.merge(opts,
        autorun: false,
        capture_log: true,
        formatters: [ExUnit.CLIFormatter, ATAM4Ex.Formatter]
      )

    # persist configuration, but don't load or run tests
    ExUnit.start(opts)

    test_dir = opts[:test_dir] || "test"

    # gets modules/test names for all loaded test modules
    load_tests(test_dir)
  end

  @doc "run the given test modules using `ExUnit`, returning the run summary."
  @spec run(async_tests :: [module], sync_tests :: [module]) :: summary
  def run(async_modules, sync_modules) do
    install_sync_modules(sync_modules)
    install_async_modules(async_modules)
    modules_loaded()

    {duration_us, summary} =
      :timer.tc(fn ->
        ExUnit.run()
      end)

    Map.put(summary, :duration_us, duration_us)
  end

  @doc """
  Dynamically requires the `*_test.exs` files from the given directory.

  This causes the test modules to be loaded into the `ExUnit` server, where
  we retrieve them for our repeated runs.

  When writing tests that we want to run once from the command line using `mix test`,
  `mix` first loads the standard `test_helper.exs` to boot-strap `ExUnit.run`, but
  when running under ATAM4Ex, we call `ExUnit.run` outselves, in `autorun: false`
  mode, so it starts the server that collects test modules, but doesn't actually run
  any test modules. We then get the collected test modules from the server and
  return them for our repeated runs.

  If present, `atam4ex_test_helper.exs` will be loaded in preference to the default
  `test_helper.exs`: it doesn't matter that `test_helper.exs` calls `ExUnit.run/0`,
  since we've already started the server ourselves, so nothing will happen.

  > Note that running this function more than once returns empty list, since Elixir
  will not load (compile) the modules again, and thus no calls will be made to the
  `ExUnit` server. That's why we have to get the tests from the server and stash them
  away.
  """
  def load_tests("" <> test_dir) do
    require_test_helper(test_dir)

    {:ok, tests} = File.ls(test_dir)

    tests =
      tests
      |> Enum.filter(fn path -> String.ends_with?(path, "_test.exs") end)
      |> Enum.map(fn path -> Path.join([test_dir, path]) end)

    {:ok, _, _} = Kernel.ParallelCompiler.require(tests)

    modules_loaded()

    async_modules = collect_async_modules()
    sync_modules = take_sync_modules() || []

    {async_modules, sync_modules}
  end

  defp require_test_helper(test_dir) do
    test_helper = Path.join([test_dir, "atam4ex_test_helper.exs"])

    if File.exists?(test_helper) do
      {:ok, _, _} = Kernel.ParallelCompiler.require([test_helper])
    else
      test_helper = Path.join([test_dir, "test_helper.exs"])
      {:ok, _, _} = Kernel.ParallelCompiler.require([test_helper])
    end
  end

  defp collect_async_modules do
    [1]
    |> Stream.cycle()
    |> Stream.map(&take_async_modules/1)
    |> Stream.take_while(fn
      nil -> false
      [] -> false
      _ -> true
    end)
    |> Enum.to_list()
  end

  defp modules_loaded() do
    ExUnit.Server.modules_loaded()
  end

  defp take_sync_modules() do
    ExUnit.Server.take_sync_modules()
  end

  defp take_async_modules(count) do
    ExUnit.Server.take_async_modules(count)
  end

  defp install_async_modules(modules) do
    Enum.each(modules, &ExUnit.Server.add_async_module/1)
  end

  defp install_sync_modules(modules) do
    Enum.each(modules, &ExUnit.Server.add_sync_module/1)
  end
end
