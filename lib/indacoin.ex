defmodule Indacoin do
  @moduledoc """
  An Elixir interface to the Indacoin API.
  """

  @indacoin_host "https://indacoin.com/"

  @doc """
  Generates a link that forwards users directly to the payment form without creating transaction via API.

  [Example](https://indacoin.com/gw/payment_form?partner=bitcoinist&cur_from=EURO&cur_to=BCD&amount=100&address=1CGETsHqcQC5xU9y3oh6FMpZE4UPKADy5m&user_id=test%40gmail.com)

  ## Parameters

    - _partner_
      - string
      - Indacoin Affiliate Program member.
    - _cur_from_
      - string
      - Currency code which defines the currency in which customer wish to do the payment;
        used to define price parameter.
      - Possible values: `USD`, `EURO`, `RUB`.
      - The minimum transaction limit is 50 USD / EUR, the maximum transaction limit is 3000 USD / EUR.
    - _cur_to_
      - string
      - Cryptocurrency code which defines the currency in which customer wish to receive payouts.
        Currency conversions are done at Indacoin.
      - [Full list of supported cryptocurrencies](https://indacoin.com/api/mobgetcurrencies)
    - _amount_
      - double
      - The price set by the customer. Example: 299.99
    - _address_
      - string
      - Wallet address for receiving payouts.
    - _user_id_
      - string
      - Customer custom ID. Using a unique value or email is strongly recommended.

  """
  def forwarding_link(params \\ []) do
    required_fields = ~w(
      partner
      cur_from
      cur_to
      amount
      address
      user_id
    )a

    if required_fields |> Enum.all?(&(has_key_and_value?(params, &1))) do
      {:ok, @indacoin_host <> "gw/payment_form?" <> URI.encode_query(params)}
    else
      {:error, "Following request params must be provided: #{Enum.join(required_fields, ", ")}"}
    end
  end

  defp has_key_and_value?(list, key) do
    if Keyword.has_key?(list, key) do
      value = Keyword.get(list, key, nil)
      cond do
        is_nil(value) -> false
        is_bitstring(value) -> String.trim(value) |> String.length > 0
        true -> true
      end
    else
      false
    end
  end
end
