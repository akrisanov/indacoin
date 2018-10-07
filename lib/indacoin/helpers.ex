defmodule Indacoin.Helpers do
  @moduledoc """
  Provides helper methods for prebaking request params.
  """

  @doc """
  Checks if all required params (keys and values) are present.
  """
  def required_params_present?(map, keys) do
    keys
    |> Enum.all?(&has_key_and_value?(map, &1))
  end

  @doc """
  Takes only presented params.
  """
  def take_params(map, keys) do
    map
    |> Map.take(keys)
    |> Enum.filter(fn {_, v} -> not_empty?(v) end)
    |> Enum.into(%{})
  end

  @doc """
  Checks if param is present.
  """
  def has_key_and_value?(map, key) do
    Map.get(map, key, nil)
    |> not_empty?
  end

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
end
