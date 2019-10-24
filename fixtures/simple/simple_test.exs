defmodule SimpleTest do
  use ExUnit.Case

  @tag category: :these_pass
  test "simple pass" do
    assert true
  end

  @tag category: :these_fail
  test "simple fail" do
    assert false
  end

  @tag skip: true
  test "skipped test" do
    assert false
  end

  @tag category: :dev_only
  test "local dev-only test" do
    assert false
  end

  test "untagged test" do
    assert false
  end

end
