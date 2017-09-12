defmodule ATAM4Ex.Environment do
  @moduledoc """
  Environment configuration - support for loading per-environment settings for use in tests.

  ATAM4Ex does not require you use this module, but supplies it as a useful utility for configuring
  suites of acceptance tests.

  In the context of ATAM4Ex, *environment* is completely different from `Mix.env` - whereas a `Mix` environment
  is some compiled code and configuation (Erlang `.app` file), for ATAM4Ex it means a particular runtime configuration
  when running tests at different stages of deployment, e.g. running in varied staging, test or production
  environments, with different hosts, keys, identifiers etc. The code, including the tests, won't change (and
  will probably be compiled for a `:prod` environment, but the configuration needs to match the realities of
  the run-time environment. It's much easier to manage this using YAML files than via `config.exs` which isn't
  designed for this purpose.

  ## Usage

  To use this module, call it in your `test_helper.exs` (or `atam4ex_test_helper.exs`), for example:
  ```
  ATAM4Ex.Environment.load_environment!(System.get_env("APP_ENV") || :local)
  ExUnit.run()
  ```
  Here we are getting the environment from an ENV-var, or, for convenience, defaulting to `:local` if that is not set.

  `load_environment/2` will attempt to load a file `<environment_id>.yaml` from the `env` directory
  (or other specified directory if specified by the `opts` argument); if the environment file cannot be found,
  or it is not valid, and exception will be thrown.

  In our tests we can then access the loaded environment via `config/0`, e.g. in `setup_all`:

  ```
  setup_all do
    config = ATAM4Ex.Environment.config()
    {:ok, config: config}
  end

  test "something", context do
    id = context[:config][:id]
    assert do_something(id)
  end
  ```
  Alternatively, just call `ATAM4Ex.Environment.config/0` or `ATAM4Ex.Environment.config!/1`
  in a test when you need it:
  ```
  test "something", context do
    id = ATAM4Ex.Environment.config!(:id)
    assert do_something(id)
  end
  ```

  We can get the current id of the environment, as an atom, with `id/0`, e.g.

  ```
  test "something else" do
    if ATAM4Ex.Environment.id() in [:prod_eu, :prod_us] do
      ...
    else
      ...
    end
  end
  ```
  Since the environment is set by the time the tests are compiled (because the test
  helper is compiled first), you can also use `ATAM4Ex.Environment.id()` to conditionally
  include code, including tests:
  ```
  if ATAM4Ex.Environment.id() === :test do
    test "something only in test environment"
      ...
    end
  end
  ```
  """

  @doc """
  Load and persist environment YAML for use as context var in tests.

  # Parameters
  `environment_id` - atom or String identifying the environment file to load.
  `opts` - overide default configuration:

  * `env_dir` - base-dir for loading environment files, default `env`.
  """
  @spec load_environment!(environment_id :: String.t | atom, opts :: Keyword.t) :: map | no_return
  def load_environment!(environment_id, opts \\ [])

  def load_environment!("" <> environment_id, opts), do: load_environment!(String.to_atom(environment_id), opts)

  def load_environment!(environment_id, opts) when is_atom(environment_id) do
    env_dir = opts[:env_dir] || "env"

    File.dir?(env_dir) || raise ArgumentError, "Directory #{env_dir} does not exist."

    path = Path.join([env_dir, to_string(environment_id) <> ".yaml"])
    env_config = ATAM4Ex.YAML.read!(path)

    Application.put_env(:atam4ex, :environment_config, env_config)
    Application.put_env(:atam4ex, :environment_id, environment_id)

    env_config
  end

  @doc "return the environment id"
  @spec id :: atom
  def id do
    Application.get_env(:atam4ex, :environment_id)
  end

  @doc "return the loaded environment configuration"
  @spec config :: map
  def config do
    Application.get_env(:atam4ex, :environment_config)
  end

  @doc """
  return the given value identified by `key` from the
  environment configuration, or thow an error if the key doesn't exist.

  NB if the key exists, but the value is `nil`, no error is thrown.
  """
  @spec config!(key :: any) :: any | no_return
  def config!(key) do
    Map.fetch!(config(), key)
  end

  @doc """
  return the given value identified by `key` from the
  environment configuration, or return `default` if the key
  does not exist.

  NB if the key exists, but the value is `nil`, `nil` is returned.
  """
  @spec config(key :: any, default :: any) :: any
  def config(key, default) do
    Map.get(config(), key, default)
  end
end
