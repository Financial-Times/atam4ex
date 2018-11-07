defmodule ATAM4ExAppTest do
  use ExUnit.Case

  setup_all do
    config = [
      server: false,
      initial_delay_ms: 0,
      period_ms: 1000,
      test_dir: "fixtures/simple",
      ex_unit: [exclude: [category: :dev_only]]
    ]
    Application.put_env(:tests, :atam4ex, config)
  end

  defmodule MYATs do
    use ATAM4Ex.Application, otp_app: :tests

    def atam4ex_opts(opts) do
      send(self(), :atam4ex_opts)
      super(opts)
    end

    def child_specs(specs) do
      send(self(), :child_specs)
      super(specs)
    end
  end

  test "using application module" do
    ExUnit.CaptureIO.capture_io(fn ->
      {:ok, pid} = MYATs.start(:normal, [])
      assert Process.alive?(pid)

      assert_receive :atam4ex_opts, 100, "Expected overridden atam4ex_opts/1 to be called"
      assert_receive :child_specs, 100, "Expected overridden child_specs/1 to be called"

      assert %{status: :too_early} = ATAM4Ex.Collector.results

      Process.sleep(500)

      assert %{status: :failures, results: all_results} = ATAM4Ex.Collector.results
      assert length(Map.keys(all_results)) == 4

      assert %{status: :all_ok, results: pass_category_results} = ATAM4Ex.Collector.results(:pass)
      assert length(Map.keys(pass_category_results)) == 1

      assert %{status: :failures, results: fail_cagegory_results} = ATAM4Ex.Collector.results(:fail)
      assert length(Map.keys(fail_cagegory_results)) == 1

      assert %{status: :all_ok} = ATAM4Ex.Collector.results(:dev_only)

      Supervisor.stop(pid)
    end)
  end

end
