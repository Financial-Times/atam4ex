defmodule ATAM4Ex.Formatter do
  @moduledoc """
  Receives test results and forwards to Collector when suite finishes.
  """

  use GenServer

  require Logger

  @doc "Initialized by `ExUnit.EventManager` passing `ExUnit` opts."
  def init(opts) do
    state = %{
      seed: opts[:seed],
      trace: opts[:trace],
      test_counter: %{},
      failure_counter: 0,
      skipped_counter: 0,
      excluded_counter: 0,
      invalid_counter: 0,
      results: %{},
      collector: opts[:collector] || ATAM4Ex.Collector
    }

    {:ok, state}
  end

  def handle_cast({:suite_finished, run_us, _load_us}, state) do
    # Logger.debug(fn -> "suite_finished #{run_us}" end)
    counter = %{
      tests: state.test_counter,
      failed: state.failure_counter,
      skipped: state.skipped_counter,
      excluded: state.excluded_counter,
      invalid: state.invalid_counter
    }

    state.collector.suite_finished(run_us, counter, state.results)
    {:noreply, state}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: nil} = test}, state) do
    Logger.debug(fn -> "test PASSED #{test.name}" end)
    state = record_test(state, test)
    {:noreply, state}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {skipped, _}} = test}, state)
      when skipped in [:skip, :skipped] do
    Logger.debug(fn -> "test SKIPPED #{test.name}" end)
    state = record_test(state, test)

    {:noreply, %{state | skipped_counter: state.skipped_counter + 1}}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:invalid, _}} = test}, state) do
    Logger.debug(fn -> "test INVALID #{test.name} invalid" end)
    state = record_test(state, test)

    {:noreply, %{state | invalid_counter: state.invalid_counter + 1}}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:failed, _failures}} = test}, state) do
    Logger.debug(fn -> "test FAILED #{test.name} failed" end)
    state = record_test(state, test)

    {:noreply, %{state | failure_counter: state.failure_counter + 1}}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:excluded, _}} = test}, state) do
    Logger.debug(fn -> "test EXCLUDED #{test.name} excluded" end)
    state = record_test(state, test)

    {:noreply, %{state | excluded_counter: state.excluded_counter + 1}}
  end

  def handle_cast(msg, state) do
    Logger.debug(fn -> "handle_cast: Received #{inspect msg}" end)
    {:noreply, state}
  end

  defp record_test(state, test) do
    test = ensure_category(test)

    %{
      state
      | results: Map.put(state.results, {test.case, test.name}, test),
        test_counter: update_test_counter(state.test_counter, test)
    }
  end

  defp ensure_category(test) do
    update_in(test.tags, fn
      tags = %{category: _} -> tags
      tags -> Map.put(tags, :category, :default)
    end)
  end

  defp update_test_counter(test_counter, %{tags: %{type: type}}) do
    Map.update(test_counter, type, 1, &(&1 + 1))
  end

  defp update_test_counter(test_counter, %{tags: %{test_type: type}}) do
    Map.update(test_counter, type, 1, &(&1 + 1))
  end
end
