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
      - decimal
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

    optional_fields = ~w(
      partner
      user_id
    )a

    params = filter_request_params(params, request_fields)

    if required_keys_and_values_present?(params, request_fields -- optional_fields) do
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

    params = filter_request_params(params, request_fields)

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

  Authorized request.

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
      - decimal
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

    params = filter_request_params(params, request_fields)

    if required_keys_and_values_present?(params, request_fields) do
      url = api_host() <> "api/exgw_createTransaction"

      body =
        params
        |> Enum.into(%{})
        |> Poison.encode!()

      do_signed_request(url, body)
    else
      error_missing_required_request_params(request_fields)
    end
  end

  @doc """
  Generates a link that forwards a user to the payment form.
  To create the request you need to get transaction ID via `create_transaction/1` method.

  Authorized request.

  [Example](https://indacoin.com/gw/payment_form?transaction_id=1154&partner=indacoin&cnfhash=Ny8zcXVWbCs5MVpGRFFXem44NW h5SE9xTitlajkydFpDTXhDOVMrOFdOOD0=)

  ## params

  Required request params:

    - _transaction_id_
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

    api_host() <> "gw/payment_form?" <> URI.encode_query(params)
  end

  @doc """
  Retrieves a list of transactions.

  Authorized request.

  ## Paging Through Results Using Offset and Limit

  - limit=10 -> Returns the first 10 records.
  - offset=5&limit=5 -> Returns records 6..10.
  - offset=10 -> Returns records 11..61 (the default number of the returned records is 50).

  ## params

  Optional request_params:

    - _user_id_
      - string
    - _tx_id_
      - string
    - _status_
      - NotFound
      - Chargeback
      - Declined
      - Cancelled
      - Failed
      - Draft
      - Paid
      - Verification
      - FundsSent
      - Finished
    - _created_at_
      - integer / timestamp
    - _hash_
      - string
    - _cur_in_
      - string
    - _cur_out_
      - string
    - _amount_in_
      - decimal
    - _amount_out_
      - decimal
    - _target_address_
      - string
    - _limit_
      - integer
    - _offset_
      - integer
  """
  def transactions_history(params \\ []) do
    request_fields = ~w(
      user_id
      tx_id
      status
      created_at
      hash
      cur_in
      cur_out
      amount_in
      amount_out
      target_address
      limit
      offset
    )a

    url = api_host() <> "api/exgw_getTransactions"

    body =
      filter_request_params(params, request_fields)
      |> Enum.into(%{})
      |> Poison.encode!()

    do_signed_request(url, body)
  end

  @doc """
  Retrieves transaction info by its id.

  Authorized request.
  """
  def transaction(id) when is_integer(id) do
    url = api_host() <> "api/exgw_gettransactioninfo"

    body =
      %{transaction_id: id}
      |> Poison.encode!()

    do_signed_request(url, body)
  end

  @doc """
  Indacoin will send a callback to your application's exposed URL when a customer makes a payment.

  _While testing, you can accept all incoming callbacks, but in production, you'll need
  to verify the authenticity of incoming requests._
  """
  def valid_callback_signature?(indacoin_signature, indacoin_nonce, user_id, tx_id) do
    message = "#{partner_name()}_#{user_id}_#{indacoin_nonce}_#{tx_id}"

    signature =
      :crypto.hmac(:sha256, secret(), message)
      |> Base.encode64()

    signature == indacoin_signature
  end

  defp api_host,
    do: Application.fetch_env!(:indacoin, :api_host)

  defp partner_name,
    do: Application.fetch_env!(:indacoin, :partner_name)

  defp secret,
    do: Application.fetch_env!(:indacoin, :secret_key)

  defp filter_request_params(list, fields) do
    Keyword.take(list, fields)
    |> Enum.filter(fn {_, v} -> not_empty?(v) end)
  end

  defp construct_signature() do
    nonce = Enum.random(100_000..1_000000)
    message = "#{partner_name()}_#{nonce}"

    signature =
      :crypto.hmac(:sha256, secret(), message)
      |> Base.encode64()

    %{nonce: nonce, value: signature}
  end

  defp do_signed_request(url, body) do
    signature = construct_signature()

    do_request(:post, url, body, [
      {:"gw-partner", partner_name()},
      {:"gw-nonce", signature[:nonce]},
      {:"gw-sign", signature[:value]}
    ])
  end

  defp do_get_request(url) do
    do_request(:get, url)
  end

  defp do_request(method, url, body \\ "", headers \\ []) do
    headers = Enum.into(headers, [{"Content-Type", "application/json"}])

    # NOTE: Indacoin can be really slow... we have to specify big timeout value
    case HTTPoison.request(method, url, body, headers, recv_timeout: 20000) do
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
