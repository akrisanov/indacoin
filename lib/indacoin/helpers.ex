defmodule Indacoin.Helpers do
  @moduledoc """
  Provides useful helper methods.
  """

  @doc """
  Checks if value is not equal to nil or not an empty string.
  """
  def not_empty?(value) do
    cond do
      is_nil(value) -> false
      is_bitstring(value) -> String.trim(value) |> String.length() > 0
      true -> true
    end
  end

  @doc """
  Checks if all required keys and values are present in a keyword list.
  """
  def required_keys_and_values_present?(list, keys) do
    keys
    |> Enum.all?(&has_key_and_value?(list, &1))
  end

  @doc """
  Checks if key and value are present in a keyword list.
  """
  def has_key_and_value?(list, key) do
    Keyword.get(list, key, nil)
    |> not_empty?
  end

  @doc """
  Returns an error with friendly message.
  """
  def error_missing_required_request_params(keys) do
    {:error, "Following request params must be provided: #{Enum.join(keys, ", ")}"}
  end
end
