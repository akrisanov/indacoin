defmodule Indacoin.HelperTest do
  use ExUnit.Case, async: true

  describe "required_params_present?/2" do
    test "returns true when all required keys are present" do
      request_params = %{"a" => "", "b" => nil, "c" => "foo", "d" => "bar"}
      required_fields = ~w(c d)
      assert true == Indacoin.Helpers.required_params_present?(request_params, required_fields)
    end

    test "returns false when at least one value is empty" do
      request_params = %{"a" => "", "b" => nil, "c" => "foo"}
      required_fields = ~w(a c)
      assert false == Indacoin.Helpers.required_params_present?(request_params, required_fields)
    end

    test "returns false when at least one value is nil" do
      request_params = %{"a" => "", "b" => nil, "c" => "foo"}
      required_fields = ~w(b c)
      assert false == Indacoin.Helpers.required_params_present?(request_params, required_fields)
    end
  end

  describe "take_params/2" do
    test "returns a new map of required params with non-empty values" do
      request_params = %{"a" => "", "b" => nil, "c" => 0, "d" => 1, "e" => 2, "f" => 3, "g" => nil}
      required_fields = ~w(a b c e)
      assert %{"c" => 0, "e" => 2} == Indacoin.Helpers.take_params(request_params, required_fields)
    end
  end

  describe "has_key_and_value?/2" do
    @params %{"a" => "", "b" => nil, "c" => 0, "d" => "foo"}

    test "returns false when a key is not present" do
      assert false == Indacoin.Helpers.has_key_and_value?(@params, :a)
    end

    test "returns false when a value is empty" do
      assert false == Indacoin.Helpers.has_key_and_value?(@params, "a")
    end

    test "returns false when a value is nil" do
      assert false == Indacoin.Helpers.has_key_and_value?(@params, "b")
    end

    test "returns true when a value is present" do
      assert true == Indacoin.Helpers.has_key_and_value?(@params, "c")
      assert true == Indacoin.Helpers.has_key_and_value?(@params, "d")
    end
  end

  describe "not_empty?/2" do
    test "returns false when a value is nil" do
      assert false == Indacoin.Helpers.not_empty?(nil)
    end

    test "returns false when a value is empty string" do
      assert false == Indacoin.Helpers.not_empty?("")
    end

    test "returns false when a value is string containg only spaces" do
      assert false == Indacoin.Helpers.not_empty?("         ")
    end

    test "returns true when a value is non-empty string" do
      assert true == Indacoin.Helpers.not_empty?("some random string")
    end

    test "returns true when value is not a string" do
      assert true == Indacoin.Helpers.not_empty?(0)
      assert true == Indacoin.Helpers.not_empty?(%{})
      assert true == Indacoin.Helpers.not_empty?([])
    end
  end
end
