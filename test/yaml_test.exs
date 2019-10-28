defmodule YamlTest do
  use ExUnit.Case
  import YamlElixir.Sigil

  test "complex yaml parsing" do
    yaml = ~y'''
    a: 1
    b:
      c:
      - "hello"
      - "goodbye"
      d:
        :env: "XXXX"
    e:
      :env: "YYYY"
      :as: "float"
    f:
      :env: "YYYY"
      :as: "integer"
    '''
    System.put_env("XXXX", "yyyy")
    System.put_env("YYYY", "10.5")

    result = ATAM4Ex.YAML.walk!(yaml)

    assert %{a: 1, b: %{c: ["hello", "goodbye"], d: "yyyy"}, e: 10.5, f: 10} == result
  end

  test "raises error for incompatible conversion value" do
    yaml = ~y'''
    a:
      :env: "ZZZZ"
      :as: "float"
    '''
    System.put_env("ZZZZ", "abc")
    assert_raise ArgumentError, fn -> result = ATAM4Ex.YAML.walk!(yaml) end
  end
end
