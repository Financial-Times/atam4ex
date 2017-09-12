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

  Your module will now be a standard OTP application which can be
  started and stopped, and will start (and stop) the tests running
  on a regular basis.

  Then add application configuration to your `mix.exs` to start
  your module as an application on VM start-up:

  ```
  def application do
    [
      extra_applications: [:logger, :ex_unit],
      mod: {MyAppAcceptanceTests, []}
    ]
  end
  ```

  ATAM4Ex will look for configuration under the `:atam4ex` key
  of the application specified by the `otp_app`, or of the 'using'
  module if not set, but you get the chance to modify this configuration
  by implementing the `atam4ex_opts/1` function, wherein you can replace
  or modify any options before returning them, e.g. you might provide
  them from another source, or replace place-holders.

    ```
  defmodule MyAcceptanceTests do
    use ATAM4Ex.Application, otp_app: myapp_ats

    def atam4ex_opts(opts) do
      Keyword.merge(opts, port: System.get_env("PORT") || 8080)
    end
  end
  ```
  """

  defmacro __using__(opts) do
    quote do
      use Application

      def start(_type, _args) do
        app = unquote(opts)[:otp_app] || Application.get_application(__MODULE__)
        opts = Application.get_env(app, :atam4ex) || []
        opts = atam4ex_opts(opts)

        config = ATAM4Ex.init(opts)
        ATAM4Ex.start_link(config)
      end

      def atam4ex_opts(opts) do
        opts
      end

      defoverridable [atam4ex_opts: 1]
    end
  end
end
