defmodule ATAM4ExAppTest do
  use ExUnit.Case

  setup_all do
    config = [server: false, initial_delay_ms: 0, period_ms: 1000, test_dir: "fixtures/simple"]
    Application.put_env(:tests, :atam4ex, config)
  end

  defmodule MYATs do
    use ATAM4Ex.Application, otp_app: :tests
  end

  test "using application module" do
    ExUnit.CaptureIO.capture_io(fn ->
      {:ok, pid} = MYATs.start(:normal, [])
      assert Process.alive?(pid)
      assert %{status: :too_early} = ATAM4Ex.Collector.results

      Process.sleep(500)

      assert %{status: :failures} = ATAM4Ex.Collector.results
      assert %{status: :all_ok} = ATAM4Ex.Collector.results(:pass)
      assert %{status: :failures} = ATAM4Ex.Collector.results(:fail)

      Supervisor.stop(pid)
    end)
  end

end
