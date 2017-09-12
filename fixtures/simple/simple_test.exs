defmodule SimpleTest do
  use ExUnit.Case

  @tag category: :pass
  test "simple pass" do
    assert true
  end

  @tag category: :fail
  test "simple fail" do
    assert false
  end

end
