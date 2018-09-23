defmodule Indacoin do
  @moduledoc """
  An Elixir interface to the Indacoin API.
  """

  import Indacoin.Helpers

  @doc """
  Returns a list of all available coins sorted by ticker.
  """
  def available_coins() do
    url = api_host() <> "api/mobgetcurrencies"

    case do_get_request(url) do
      {:ok, body} ->
        coins =
          body
          |> Enum.filter(fn res -> res["isActive"] == true end)
          |> Enum.sort_by(fn res -> {res["short_name"]} end)

        {:ok, coins}

      {:error, reason} ->
        {:error, reason}
    end
  end

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

    # keep only allowed params
    params = Keyword.take(params, request_fields)

    if required_keys_and_values_present?(params, request_fields) do
      {:ok, api_host() <> "gw/payment_form?" <> URI.encode_query(params)}
    else
      error_missing_required_request_params(request_fields)
    end
  end

  defp api_host,
    do: Application.fetch_env!(:indacoin, :api_host)

  defp do_get_request(url, headers \\ []) do
    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Poison.decode(body) do
          {:ok, decoded} -> {:ok, decoded}
          {:error, error} -> {:error, error}
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, status_code}

      {:error, error} ->
        {:error, error}
    end
  end
end
