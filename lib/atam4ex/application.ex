defmodule ATAM4Ex.Application do
  @moduledoc """
  Provides application template for running ATAM4Ex.

  ## Usage
  In your test app, define a module and `use ATAM4Ex.Application`:

  ```
  defmodule MyAcceptanceTests do
    use ATAM4Ex.Application, otp_app: :myapp_ats
  end
  ```

  Your module will now be a standard Elixir Application module which can be
  started and stopped, and will start (and stop) the tests running
  on a regular basis.

  ATAM4Ex will look for configuration under the `:atam4ex` key
  of the application specified by the `otp_app`, or of the application
  hosting the  module if `otp_app` is not stated.

  In order to start your application automatically, add your module to the `application/0`
  function in your `mix.exs`:

  ```
  def application do
    [
      extra_applications: [:logger],
      mod: {MyAppAcceptanceTests, []}
    ]
  end
  ```

  ## Callbacks
  You get the chance to modify this configuration after loading by implementing
  the `atam4ex_opts/1` function in your module, wherein you can replace or modify
  any options before returning them, e.g. you might provide them from another source,
  or replace place-holders:

  ```
  defmodule MyAcceptanceTests do
    use ATAM4Ex.Application, otp_app: myapp_ats

    def atam4ex_opts(opts) do
      # set the server port, unless disabled
      if not opts[:server] == false do
        {port, _} = Integer.parse(System.get_env("PORT") || "9090")
        Keyword.update(opts, :server, [port: port], &(Keyword.merge(&1, [port: port])))
      else
        opts
      end
    end
  end
  ```

  You can also modify the child-specs list created by the `ATAM4Ex` supervisor by implementing a
  `child_specs/1` function in your application module; this receives ATAM4Ex's supervisor's
  child specs, and you can add additional specs to the list:
  ```
  def child_specs(specs) do
    use Supervisor
    specs ++ [supervisor(MyAcceptanceTests.MyAdditionalSupervisor, [])]
  end
  ```
  """

  defmacro __using__(use_opts) do
    quote do
      use Application

      def start(_type, _args) do
        app = unquote(use_opts)[:otp_app] || Application.get_application(__MODULE__)

        init_opts = Application.get_env(app, :atam4ex) || []
        init_opts = atam4ex_opts(init_opts)

        callback = unquote(use_opts)[:callback] || __MODULE__

        config = ATAM4Ex.init(init_opts)
        ATAM4Ex.start_link(config, callback)
      end

      def child_specs(children) do
        children
      end

      def atam4ex_opts(opts) do
        opts
      end

      defoverridable atam4ex_opts: 1, child_specs: 1
    end
  end
end
