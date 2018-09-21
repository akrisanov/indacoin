defmodule Indacoin do
  @moduledoc """
  An Elixir interface to the Indacoin API.
  """

  import Indacoin.Helpers

  @indacoin_host "https://indacoin.com/"

  @doc """
  Generates a link that forwards users directly to the payment form without creating transaction via API.

  [Example](https://indacoin.com/gw/payment_form?partner=bitcoinist&cur_from=EURO&cur_to=BCD&amount=100&address=1CGETsHqcQC5xU9y3oh6FMpZE4UPKADy5m&user_id=test%40gmail.com)

  ## params

  Required request params:

    - _partner_
      - string
      - Indacoin Affiliate Program member.
    - _cur_from_
      - string
      - Currency code which defines the currency in which customer wish to do the payment;
        used to define price parameter.
      - Possible values: `USD`, `EURO`, `RUB`.
    - _cur_to_
      - string
      - Cryptocurrency code which defines the currency in which customer wish to receive payouts.
        Currency conversions are done at Indacoin.
      - [Full list of supported cryptocurrencies](https://indacoin.com/api/mobgetcurrencies)
    - _amount_
      - double
      - The price set by the customer. Example: 299.99
      - The minimum transaction limit is `50 USD/EUR`.
      - The maximum transaction limit is `3000 USD/EUR`.
    - _address_
      - string
      - Wallet address for receiving payouts.
    - _user_id_
      - string
      - Customer custom ID. Using a unique value or email is strongly recommended.

  """
  def forwarding_link(params) do
    request_fields = ~w(
      partner
      cur_from
      cur_to
      amount
      address
      user_id
    )a

    if required_keys_and_values_present?(params, request_fields) do
      {:ok, @indacoin_host <> "gw/payment_form?" <> URI.encode_query(params)}
    else
      error_missing_required_request_params(request_fields)
    end
  end
end
