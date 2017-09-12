defmodule ATAM4Ex.Collector do
  require Logger

  use GenServer

  @type status :: :too_early | :failures | :all_ok

  defstruct results: %{}, status: :too_early, duration_us: 0

  @type t :: %ATAM4Ex.Collector{results: map, status: status}


  def suite_finished(run_us, counter, results) do
    GenServer.cast(__MODULE__, {:suite_finished, run_us, counter, results})
  end

  def results() do
    GenServer.call(__MODULE__, :results)
  end

  def results(category) do
    GenServer.call(__MODULE__, {:results, category})
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, %__MODULE__{}}
  end

  def handle_cast({:suite_finished, run_us, counter, results}, state) do
    Logger.info(fn -> "#{__MODULE__} Suite finished in #{System.convert_time_unit(run_us, :microseconds, :milliseconds)}ms; #{inspect counter}" end)

    state = case counter do
      %{failed: n} when n > 0 -> %{state | status: :failures}
      %{invalid: n} when n > 0 -> %{state | status: :failures}
      _other -> %{state | status: :all_ok}
    end

    {:noreply, %{state | results: results, duration_us: run_us}}
  end

  def handle_call(:results, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:results, _tag}, _from, state = %{status: :too_early}) do
    {:reply, state, state}
  end

  def handle_call({:results, category}, _from, state) do
    tests = Enum.filter(state.results, fn
        {_key, test} -> test.tags[:category] === category
    end)

    has_failures = Enum.any?(tests, fn
      {_key, %{state: {:failed, _}}} -> true
      {_key, %{state: {:invalid, _}}} -> true
      _ -> false
    end)
    has_failures = if(has_failures, do: :failures, else: :all_ok)

    {:reply, struct(__MODULE__, results: tests, status: has_failures), state}
  end

end
