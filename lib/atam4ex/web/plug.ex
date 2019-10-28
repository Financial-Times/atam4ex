defmodule ATAM4Ex.ATAM4JCompatiblePlug do
  @moduledoc """
  Plug to serve test results in [ATAM4J](https://github.com/atam4j/atam4j) compatible JSON format.

  ## Endpoints
  * `/tests` -  results for all tests.
  * `/tests/:category` - results for given category, if supported.

  Categories must be configured in `init/1`; the `:default` category is
  always added to the list.

  The serialization format looks like the following:

  ```json
  {
    "tests": [
      {
        "passed": false,
        "testCategory": "critical",
        "testClass": "MyATAM.SomeTest",
        "testName": "test_a"
      }
    ],
    "status": "FAILURES"
  }
  ```

  The `status` property will be:
  * `FAILURES` if there are any test failures.
  * `ALL_OK` if all tests pass.
  * `TOO_EARLY` if tests haven't run to completion yet.

  """

  @behaviour Plug

  import Plug.Conn

  @impl Plug
  def init(opts) do
    categories = opts[:categories] || []
    categories = if(:default in categories, do: categories, else: [:default | categories])

    %{
      # map categories to String for matching
      categories: Enum.map(categories, &to_string/1)
    }
  end

  @impl Plug
  def call(%{path_info: [category]} = conn, %{categories: categories}) do
    if category in categories do
      send_category(conn, category)
    else
      send_resp(conn, 404, "Category #{category} Not Found.")
    end
  end

  @impl Plug
  def call(%{path_info: []} = conn, _config) do
    send_all(conn)
  end

  def send_category(conn, category) do
    results = ATAM4Ex.Collector.results(String.to_existing_atom(category))

    case results do
      %{status: :too_early} ->
        send_too_early(conn)

      _ ->
        send_json(conn, format(results))
    end
  end

  def send_all(conn) do
    results = ATAM4Ex.Collector.results()

    case results do
      %{status: :too_early} ->
        send_too_early(conn)

      _ ->
        send_json(conn, format(results))
    end
  end

  def send_json(conn, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(data))
  end

  def send_too_early(conn) do
    send_resp(conn, 200, ~s({"status": "TOO_EARLY"}))
  end

  def format(%{results: results, status: status}) do
    %{
      "tests" => Enum.map(results, fn {_key, val} -> to_schema(val) end),
      "status" => String.upcase(Atom.to_string(status))
    }
  end

  def to_schema(%ExUnit.Test{name: test_name, case: test_case, tags: tags, state: state}) do
    passed = to_pass(state)

    %{
      "testClass" => test_case,
      "testName" => test_name,
      "category" => tags[:category] || "default",
      "passed" => passed
    }
  end

  def to_pass(nil), do: true
  def to_pass(%{skip: _}), do: true
  def to_pass(_), do: false
end
