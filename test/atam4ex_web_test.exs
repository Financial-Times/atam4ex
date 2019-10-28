defmodule ATAM4ExHttpServerTest do
  use ExUnit.Case
  @moduletag :http_server

  setup_all do
    config = [
      server: [port: 8081],
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

      :inets.start()

      assert_receive :atam4ex_opts, 100, "Expected overridden atam4ex_opts/1 to be called"
      assert_receive :child_specs, 100, "Expected overridden child_specs/1 to be called"

      assert %{status: :too_early} = ATAM4Ex.Collector.results()

      Process.sleep(500)

      assert %{status: :failures, results: all_results} = ATAM4Ex.Collector.results()
      assert length(Map.keys(all_results)) == 5

      assert %{status: :all_ok, results: pass_category_results} =
               ATAM4Ex.Collector.results(:these_pass)

      assert length(Map.keys(pass_category_results)) == 1

      assert %{status: :failures, results: fail_category_results} =
               ATAM4Ex.Collector.results(:these_fail)

      assert length(Map.keys(fail_category_results)) == 1

      assert %{status: :all_ok} = ATAM4Ex.Collector.results(:dev_only)

      assert %{status: :failures, results: all_results} = ATAM4Ex.Collector.results()
      assert length(Map.keys(all_results)) == 5

      assert {:ok, res} = :httpc.request(String.to_charlist("http://localhost:8081/tests"))
      assert {{_, 200, _}, _headers, body} = res

      body =
        body
        |> to_string()
        |> Jason.decode!()

      assert body["status"] == "FAILURES"
      assert body["tests"]
      assert length(body["tests"]) == 5

      Supervisor.stop(pid)
    end)
  end
end
