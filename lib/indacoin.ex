defmodule Indacoin do
  @moduledoc """
  An Elixir interface to the Indacoin API.
  """

  import Indacoin.Helpers

  @doc """
  Retrieves a list of all available coins sorted by ticker.
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
  Generates a link that forwards a user directly to the payment form without creating transaction via API.

  [Example](https://indacoin.com/gw/payment_form?partner=bitcoinist&cur_from=EURO&cur_to=BCD&amount=100&address=1CGETsHqcQC5xU9y3oh6FMpZE4UPKADy5m&user_id=test%40gmail.com)

  [LIGHT INTEGRATION](https://indacoin.com/en_US/api)

  ## params

  Required request params:

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

  Optional request params:

    - _partner_
      - string
      - Indacoin Affiliate Program member.
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

  @doc """
  Gets value of amount that customer will get once payment transaction finished.
  """
  def transaction_price(params) do
    request_fields = ~w(
      cur_from
      cur_to
      amount
      partner
      user_id
    )a

    optional_fields = ~w(
      partner
      user_id
    )a

    # keep only allowed params
    params = Keyword.take(params, request_fields)

    if required_keys_and_values_present?(params, request_fields -- optional_fields) do
      url =
        api_host() <>
          "api/GetCoinConvertAmount/" <>
          "#{params[:cur_from]}/#{params[:cur_to]}/#{params[:amount]}/#{params[:partner]}/#{params[:user_id]}"

      do_request(:get, url)
    else
      error_missing_required_request_params(request_fields)
    end
  end

  @doc """
  Drafts payment transaction and returns its ID.

  [STANDARD INTEGRATION](https://indacoin.com/en_US/api)

  ## params

  Required request params:

    - _user_id_
      - string
      - Customer custom ID. Using a unique value or email is strongly recommended.
    - _cur_in_
      - string
      - Currency code which defines the currency in which customer wish to do the payment;
        used to define price parameter.
      - Possible values: `USD`, `EURO`, `RUB`.
    - _cur_out_
      - string
      - Cryptocurrency code which defines the currency in which customer wish to receive payouts.
        Currency conversions are done at Indacoin.
      - [Full list of supported cryptocurrencies](https://indacoin.com/api/mobgetcurrencies)
    - _target_address_
      - string
      - Wallet address for receiving payouts.
    - _amount_in_
      - double
      - The price set by the customer. Example: 299.99
      - The minimum transaction limit is `50 USD/EUR`.
      - The maximum transaction limit is `3000 USD/EUR`.
  """
  def create_transaction(params) do
    request_fields = ~w(
      user_id
      cur_in
      cur_out
      target_address
      amount_in
    )a

    # keep only allowed params
    params = Keyword.take(params, request_fields)

    if required_keys_and_values_present?(params, request_fields) do
      url = api_host() <> "api/exgw_createTransaction"
      body = Poison.encode!(Enum.into(params, %{}))
      signature = construct_signature()

      do_request(:post, url, body, [
        {:"gw-partner", partner_name()},
        {:"gw-nonce", signature[:nonce]},
        {:"gw-sign", signature[:value]}
      ])
    else
      error_missing_required_request_params(request_fields)
    end
  end

  @doc """
  Generates a link that forwards a user to the payment form.
  To create the request you need to get transaction ID via `create_transaction/1` method.

  [Example](https://indacoin.com/gw/payment_form?transaction_id=1154&partner=indacoin&cnfhash=Ny8zcXVWbCs5MVpGRFFXem44NW h5SE9xTitlajkydFpDTXhDOVMrOFdOOD0=)

  ## params

  Required request params:

    - _transaction_id_:
      - integer
  """
  def transaction_link(transaction_id) do
    message = "#{partner_name()}_#{transaction_id}"

    signature =
      :crypto.hmac(:sha256, secret(), message)
      |> Base.encode64()
      |> Base.encode64()

    params = [
      transaction_id: transaction_id,
      partner: partner_name(),
      cnfhash: signature
    ]

    {:ok, api_host() <> "gw/payment_form?" <> URI.encode_query(params)}
  end

  defp api_host,
    do: Application.fetch_env!(:indacoin, :api_host)

  defp partner_name,
    do: Application.fetch_env!(:indacoin, :partner_name)

  defp secret,
    do: Application.fetch_env!(:indacoin, :secret_key)

  defp construct_signature() do
    nonce = Enum.random(100_000..1_000000)
    message = "#{partner_name()}_#{nonce}"

    signature =
      :crypto.hmac(:sha256, secret(), message)
      |> Base.encode64()

    %{nonce: nonce, value: signature}
  end

  defp do_get_request(url) do
    do_request(:get, url)
  end

  defp do_request(method, url, body \\ "", headers \\ []) do
    headers = Enum.into(headers, [{"Content-Type", "application/json"}])

    case HTTPoison.request(method, url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Poison.decode(body) do
          {:ok, decoded} ->
            cond do
              is_bitstring(decoded) -> {:error, decoded}
              true -> {:ok, decoded}
            end

          {:error, error} ->
            {:error, error}
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, status_code}

      {:error, error} ->
        {:error, error}
    end
  end
end
