defmodule ATAM4Ex.ExUnit do
  @moduledoc """
  Integration with `ExUnit.

  ## Parameters
  `opts` - Keyword list of options:
  * test_dir - directory to load tests from, default "test".

  For other options, see ExUnit, however, `autorun`, `capture_log` and `formatters`
  are not settable.
  """

  @type summary :: %{duration_us: non_neg_integer, failures: non_neg_integer, skipped: non_neg_integer, total: non_neg_integer}

  @doc "dynamically require tests from `*_test.exs` files and return tuple with async and sync tests"
  @spec init(opts :: Keyword.t) :: {async_cases :: [module], sync_cases :: [module]}
  def init(opts) do
    opts = Keyword.merge(opts, [autorun: false, capture_log: true, formatters: [ExUnit.CLIFormatter, ATAM4Ex.Formatter]])
    ExUnit.start(opts) # persist configuration, but don't load or run tests

    test_dir = opts[:test_dir] || "test"

    load_tests(test_dir) # gets modules/test names for all loaded cases
  end

  @doc "run the given test cases using `ExUnit`, returning the run summary."
  @spec run(async_tests :: [module], sync_tests :: [module]) :: summary
  def run(async_cases, sync_cases) do
    install_sync_cases(sync_cases)
    install_async_cases(async_cases)
    ExUnit.Server.cases_loaded()
    {duration_us, summary} = :timer.tc(fn ->
      ExUnit.run
    end)
    Map.put(summary, :duration_us, duration_us)
  end

  @doc """
  Dynamically requires the `*_test.exs` files from the given directory.

  This causes the test cases to be loaded into the `ExUnit` server, where
  we retrieve them for our repeated runs.

  When writing tests that we want to run once from the command line using `mix test`,
  `mix` first loads the standard `test_helper.exs` to boot-strap `ExUnit.run`, but
  when running under ATAM4Ex, we call `ExUnit.run` outselves, in `autorun: false`
  mode, so it starts the server that collects test cases, but doesn't actually run
  any test cases. We then get the collected test cases from the server and
  return them for our repeated runs.

  If present, `atam4ex_test_helper.exs` will be loaded in preference to the default
  `test_helper.exs`: it doesn't matter that `test_helper.exs` calls `ExUnit.run/0`,
  since we've already started the server ourselves, so nothing will happen.

  > Note that running this function more than once achieves nothing, since Elixir
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

    Kernel.ParallelRequire.files(tests)

    ExUnit.Server.cases_loaded()

    async_cases = collect_async_cases()
    sync_cases = ExUnit.Server.take_sync_cases() || []

    {async_cases, sync_cases}
  end

  defp require_test_helper(test_dir) do
    test_helper = Path.join([test_dir, "atam4ex_test_helper.exs"])
    if File.exists?(test_helper) do
      Kernel.ParallelRequire.files([test_helper])
    else
      test_helper = Path.join([test_dir, "test_helper.exs"])
      Kernel.ParallelRequire.files([test_helper])
    end
  end

  defp collect_async_cases do
    [1]
    |> Stream.cycle()
    |> Stream.map(&ExUnit.Server.take_async_cases/1)
    |> Stream.take_while(fn
      nil -> false
      [] -> false
      _ -> true
    end)
    |> Enum.to_list()
  end

  defp install_async_cases(cases) do
    Enum.each(cases, &ExUnit.Server.add_async_case/1)
  end
  defp install_sync_cases(cases) do
    Enum.each(cases, &ExUnit.Server.add_sync_case/1)
  end

end
