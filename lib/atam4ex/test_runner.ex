defmodule ATAM4Ex.TestSuper do
  @moduledoc """
  Supervisor for TestRunner.

  Start using the `%ATAM4Ex{}` configuration created by `ATAM4Ex.init/1`.

  ```
  {:ok, pid} = ATAM4EX.TestSuper.start_link(config)
  ```
  """
  use Supervisor

  require Logger

  def start_link(%ATAM4Ex{} = config) do
    # Logger.debug(fn -> "#{__MODULE__}.start_link/1 #{inspect self()}" end)
    Supervisor.start_link(__MODULE__, [config])
  end

  @doc false
  def init([%ATAM4Ex{} = config]) do
    # Logger.debug(fn -> "#{__MODULE__}.init/1 #{inspect self()}" end)

    children = [
      worker(ATAM4Ex.TestRunner, [config]) # supply config as first argument for Fettle.Runner workers
    ]

    supervise(children, strategy: :one_for_one)
  end

end

defmodule ATAM4Ex.TestRunner do
  @moduledoc """
  GenServer that runs ExUnit tests periodically.

  NB this should be started from `ATAM4Ex.TestSuper` to ensure scheduling starts;
  starting directly through `start_link/1` is not supported due to `self()` being
  the calling process in `init/1` rather than the child `TestRunner` process:
  you may get around this by calling `schedule_test_run/2`, and passing the `TestRunner` child
  pid, to kick off the scheduling.
  """

  use GenServer

  require Logger

  def start_link(%ATAM4Ex{} = config) do
    # Logger.debug(fn -> "#{__MODULE__}.start_link/1 #{inspect self()}" end)
    GenServer.start_link(__MODULE__, [config, self()], name: __MODULE__)
  end

  def init([config = %ATAM4Ex{}, parent_pid]) do
    # Logger.debug(fn -> "#{__MODULE__}.init/1 #{inspect self()} (parent #{inspect parent_pid}" end)
    if(parent_pid != self(), do: schedule_first_test_run(config), else: Logger.warn(fn -> "Non-Supervised start-up" end))
    {:ok, config}
  end

  def schedule_first_test_run(%ATAM4Ex{initial_delay_ms: ms}) do
    Logger.info(fn -> "Scheduling *initial* test run in #{ms}ms" end)
    schedule_test_run(self(), ms)
  end

  def schedule_test_run(after_ms) do
    schedule_test_run(self(), after_ms)
  end

  def schedule_test_run(pid, after_ms) do
    Logger.info(fn -> "Scheduling test run in #{after_ms}ms" end)
    Process.send_after(pid, :scheduled_run, after_ms)
  end

  def handle_info(:scheduled_run, %ATAM4Ex{} = state) do
    # Logger.debug(fn -> "Starting scheduled test run" end)
    parent = self()
    task = spawn_monitor(fn ->
      # Logger.debug(fn -> "Running tests #{inspect self()}" end)
      summary = run_tests(state)
      send(parent, {:test_run_result, summary})
    end)
    {:noreply, %{state | runner_task: task}, state.timeout_ms}
  end

  def handle_info({:test_run_result, summary}, %ATAM4Ex{} = state) do
    # Logger.debug(fn -> "Received test results: #{inspect summary}" end)
    {:noreply, %{state | last_result: summary}}
  end

  def handle_info(:timeout, %ATAM4Ex{runner_task: {pid, _ref}} = state) do
    Logger.info(fn -> "Test run timed out in #{inspect pid}" end)

    Process.exit(pid, :kill)

    {:noreply, %{state | last_result: :timeout}}
  end

  @doc false
  def handle_info({:DOWN, _ref, :process, _pid, :normal}, %ATAM4Ex{period_ms: ms} = state) do
    # sub-process exited normally: reschedule
    # Logger.debug(fn -> "Test runner #{inspect pid} exited normally; reschedule in #{ms}ms" end)
    schedule_test_run(ms)

    {:noreply, %{state | runner_task: nil}}
  end

  @doc false
  def handle_info({:DOWN, _ref, :process, _pid, :killed}, %ATAM4Ex{} = state) do
    # sub-process was killed, hopefully by us: reschedule
    # Logger.debug(fn -> "Test run in #{inspect pid} was killed" end)
    schedule_test_run(state.period_ms)

    {:noreply, %{state | runner_task: nil}}
  end

  @doc false
  def handle_info({:DOWN, _ref, :process, pid, reason}, %ATAM4Ex{period_ms: ms} = state) do
    # sub-process died, reschedule check
    Logger.warn(fn -> "Test run process #{inspect pid} died: #{inspect reason}" end)

    schedule_test_run(ms)

    {:noreply, %{state | last_result: :error}}
  end

  def handle_info(message, state) do
    Logger.warn(fn -> inspect({:unknown_message, message, %ATAM4Ex{} = state}) end)
    {:noreply, state}
  end

  def run_tests(%{async_cases: async_cases, sync_cases: sync_cases}) do
    ATAM4Ex.ExUnit.run(async_cases, sync_cases)
  end

end
