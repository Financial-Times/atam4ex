# ATAM4Ex - **A**cceptance **T**ests **A**s **M**onitors - for **E**li**X**ir

Provides a framework for repeatedly running `ExUnit` tests and exposing the results in
a standard format.

The original [ATAM4J](https://github.com/atam4j) Java framework was developed at the FT, 
and is used for monitoring SLAs. ATAM4Ex provides the same functionality as an Elixir project,
which makes the acceptance tests more robust, avoiding memory leaks and stateful crashes.

## Synopsis

Tests are written as standard [ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html) tests, and
thus may be run stand-alone with `mix test`, as well as under the ATAM4Ex supervisor.

An application which is host to the acceptance tests starts the ATAM4Ex supervisor tree, 
optionally with a Cowboy/Plug web-server, either using `ATAM4Ex.init/1` and `ATAM4Ex.start_link/1`,
giving it full control over the configuration and start-up, or by using the `ATAM4Ex.Application` module in its registered application module:

```elixir
defmodule MyAppATs do
    use ATAM4Ex.Application, otp_app: :myapp_at
end
```

The `otp_app` option allows specifying the root of the configuration, in this case the ATAM4Ex configuration will be loaded (e.g. via `config.exs`) such that it is available via 
`Application.get_env(:myapp_at, :atam4ex)`: 

```elixir
config :myapp_at, :atam4ex,
    initial_delay_ms: 10_000,
    period_ms: 30_000,
    timeout_ms: 120_000,
    ex_unit: [max_cases: 2, timeout: 5_000]
```

For details of all the configuration options, see the `ATAM4Ex` module.

The application can then be registered in `mix.exs` so that it starts when the BEAM VM starts:

```elixir
def application do
[
    mod: {MyAppATs, []},
    extra_applications: [:logger, :ex_unit]
]
end
```

> Note the `extra_applications` dependency on `ex_unit` - this is important for releases, else `ExUnit` modules will not be included; see below.

You can then start your application using `mix` with (`--no-halt` keeps the application running to run the tests):
```
$ mix run --no-halt
```

or in IEx with:
```
iex -S mix
```

Test results will also be reported, as normal, to the console, so details of failures etc. appear in the application logs.

Test results can also be obtained programatically by calling `ATAM4Ex.Collector.results/0` (or `ATAM4Ex.Collector.results/1`),
which is what the Web Server does.

## Default Web server

Unless the `server: false` configuration option is given, ATAM4Ex will start an HTTP server 
(on port `8080` by default), configured with the list of options on the `server` configuration
property. e.g. to serve TLS you might put the following in `config.exs`:

```
config :myapp_at, :atam4ex,
  server: [port: 8443, scheme: :https, certfile: "/path/to/certfile", keyfile: "/path/to/keyfile"]
```

> See `Plug.Adapters.Cowboy` module for details of all the options, including those for running under TLS.

The server responds to requests on the `/tests` path.

### Response Format

The server serves test results in ATAM4J's JSON format, which is a list of `tests`, each
with a `passed` flag, and an overall `status`, which is `"ALL_OK"` if all tests are passing, e.g.

```
$ curl 'http://localhost:8080/tests'
{"tests":[{"testName":"test user by id","testClass":"Elixir.GraphqlATTest","passed":true,"category":"critical"}],"status":"ALL_OK"}
```

Other values for `status` are `TOO_EARLY`, i.e. the tests haven't run yet, and `FAILURES` which mean some
tests have failed.

The HTTP status is always `200`, regardless of results.

### Categories
It's also possible to retrieve a status for certain categories of tests, tagged with a `@tag category: <atom>`:

```elixir
@tag category: :critical
test "something that is critical" do
  ...
end
```

You can then retrieve results, and a status only for that category of tests, via e.g.
```
$ curl http://localhost:8080/tests/critical
{"tests":[{"testName":"test user by id","testClass":"Elixir.GraphqlATTest","passed":true,"category":"critical"}],"status":"ALL_OK"}
```

If you are using the default settings, and therefore `ATAM4Ex.Router`, there are two categories
defined, `:critial` and `:default`; other categories will be rejected. Tests not tagged with a category
will be placed in the `:default` category.

## Test Environment

ATAM4Ex supports loading a test environment (AKA configuration) via YAML files. This optional
feature allows different configurations to be used for various run-time environments, e.g. host names, and api-keys are likely to be different in staging and production environments, and is more flexible
than using `config.exs` (which is intended for build environments, not deployment environments).

The `ATAM4Ex.Environment` module can load YAML files, by default from an `env` directory 
(which should be packaged with your app). Usually you would do this in your `test_helper.exs` file:

```elixir
# load environment specified in APP_ENV, or local
ATAM4Ex.Environment.load_environemnt!(System.get_env("APP_ENV") || :local)
ExUnit.start
```

Tests can then access the environment settings via `ATAM4Ex.Environment.config/0` (or `config/1`) at any point in their execution, e.g. during `setup` to provide a `context`, or during the test itself.


The YAML parser provides a mechanism for resolving system environment variables via `:env` keys, e.g.
if your `env/production.yaml` file contained:

```yaml
system_url: https://my-system-prod
system_api_key:
    :env: SYSTEM_API_KEY
```

`ATAM4Ex.Environment.config(:system_api_key)` will be resolved at load time to be the value of the `SYSTEM_API_KEY` environment variable, replacing it's original map structure.

> Note that for convenience, map keys in the YAML will be converted to atoms.

## Installation

For the bleeding edge, latest and most unstable version, add to your `mix.exs` file:

```elixir
def deps do
  [
    {:atam4ex, gitub: "Financial-Times/atam4ex"}
  ]
end
```

## Building a Release with Distillery

The point of ATAM is that your tests run continuously somewhere; for this purpose you probably
want to make a stand-alone release, rather than relying on `mix`. 

Here's how:

1. Ensure that your test application's `mix.exs` lists `:ex_unit` as an `extra_applications` entry, otherwise the `ExUnit` BEAM modules will be missing from your release, and your app will fail
on start-up complaining of missing ExUnit modules:
```elixir
def application do
[
    mod: {MyAppATs, []},
    extra_applications: [:logger, :ex_unit]
]
end
``` 

2. You need to copy your tests and environment files to the release, else it won't be able to find them. Assuming you are using
the default `test` and `env` directories, add `set overlays` entries to your `rel/config.exs`:

```elixir
release :myapp_at do
  set version: current_version(:myapp_at)
  set overlays: [
    {:mkdir, "test"},
    {:copy, "test", "test"},
    {:mkdir, "env"},
    {:copy, "env", "env"}
  ]
end
```

This copies the `test` and `env` dirs to the `releases` directory, see [Overlays](https://hexdocs.pm/distillery/overlays.html#content) and [Configuration](https://hexdocs.pm/distillery/configuration.html) in the [Distillery](https://hexdocs.pm/distillery) docs.

That's it. Otherwise it's a standard Elixir application.
