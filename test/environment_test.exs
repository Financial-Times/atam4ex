defmodule ATAM4ExEnvironmentTest do
  use ExUnit.Case

  test "Load missing Environment" do
    System.put_env("TEST_VAR", "Hello")
    error = catch_error(ATAM4Ex.Environment.load_environment!(:none, env_dir: "fixtures/env"))
    assert error
    assert %YamlElixir.FileNotFoundError{message: message} = error
    assert String.contains?(message, "fixtures/env/none.yaml")
  end

  test "Load missing Environment vars" do
    System.delete_env("TEST_VAR")

    assert_raise ArgumentError, fn ->
      ATAM4Ex.Environment.load_environment!(:test, env_dir: "fixtures/env")
    end
  end

  test "Load valid Environment" do
    System.put_env("TEST_VAR", "Hello")
    ATAM4Ex.Environment.load_environment!(:test, env_dir: "fixtures/env")
  end

  test "Use valid Environment" do
    System.put_env("TEST_VAR", "Hello")
    env = ATAM4Ex.Environment.load_environment!(:test, env_dir: "fixtures/env")

    assert env[:key1] == "value1"
    assert env[:key2] == "Hello"
  end
end
