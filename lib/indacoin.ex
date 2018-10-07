defmodule Indacoin do
  @moduledoc """
  An Elixir interface to the Indacoin API.

  ## List Of Requests Params

  - _cur_from_ :: string – Currency code which defines the currency in which customer wish to do the payment;
    used to define price parameter. Possible values: `USD`, `EURO`, `RUB`.
  - _cur_in_ :: string `^^^`
  - _cur_to_ :: string – Cryptocurrency code which defines the currency in which customer wish to receive payouts.
    Currency conversions are done at Indacoin.
    [Full list of supported cryptocurrencies](https://indacoin.com/api/mobgetcurrencies)
  - _cur_out_ :: string `^^^`
  - _amount_ :: decimal – The price set by the customer. Example: `299.99`
    The minimum transaction limit is `50 USD/EUR`.
    The maximum transaction limit is `3000 USD/EUR`.
  - _amount_in_ :: decimal `^^^`
  - _address_ :: string – Wallet address for receiving payouts.
  - _target_address_ :: string `^^^`
  - _partner_ :: string – Indacoin Affiliate Program member.
  - _user_id_ :: string – Customer custom ID. Using a unique value or email is strongly recommended.

  ## Transaction Statuses

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

  ["LIGHT INTEGRATION"](https://indacoin.com/en_US/api)

  ## params

  Required request params:

    - _cur_from_ :: string
    - _cur_to_ :: string
    - _amount_ :: decimal
    - _address_ :: string
    - _partner_ :: string

  Optional request params:

    - _user_id_ :: string
  """
  def forwarding_link(params) do
    required_params = ~w(
      cur_from
      cur_to
      amount
      address
      partner
    )

    optional_params = ~w(
      user_id
    )

    params = take_params(params, required_params ++ optional_params)

    if required_params_present?(params, required_params) do
      {:ok, api_host() <> "gw/payment_form?" <> URI.encode_query(params)}
    else
      missing_required_request_params(required_params)
    end
  end

  @doc """
  Gets value of amount that customer will get once payment transaction finished.

  ## params

  Required request params:

    - _cur_from_ :: string
    - _cur_to_ :: string
    - _amount_ :: decimal

  Optional request params:

    - _partner_ :: string
    - _user_id_ :: string
  """
  def transaction_price(params \\ %{}) do
    case transaction_price_request_url(params) do
      {:ok, url} -> do_request(:get, url)
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  false
  """
  def transaction_price_request_url(params \\ %{}) do
    required_params = ~w(
      cur_from
      cur_to
      amount
    )

    optional_params = ~w(
      partner
      user_id
    )

    params = take_params(params, required_params ++ optional_params)

    if required_params_present?(params, required_params) do
      # params order is important for this request!
      query_params =
        (required_params ++ optional_params)
        |> Enum.map(fn k -> Map.get(params, k) end)
        |> Enum.reject(&is_nil/1)
        |> Enum.join("/")

      {:ok, api_host() <> "api/GetCoinConvertAmount/" <> query_params}
    else
      missing_required_request_params(required_params)
    end
  end

  @doc """
  Drafts payment transaction and returns its ID.

  _Signed API request._

  ["STANDARD INTEGRATION"](https://indacoin.com/en_US/api)

  ## params

  Required request params:

    - _user_id_ :: string
    - _cur_in_ :: string
    - _cur_out_ :: string
    - _target_address_ :: string
    - _amount_in_ :: decimal
  """
  def create_transaction(params) do
    required_params = ~w(
      user_id
      cur_in
      cur_out
      target_address
      amount_in
    )

    params = take_params(params, required_params)

    if required_params_present?(params, required_params) do
      url = api_host() <> "api/exgw_createTransaction"
      body = Jason.encode!(params)
      do_signed_request(url, body)
    else
      missing_required_request_params(required_params)
    end
  end

  @doc """
  Generates a link that forwards a user to the payment form.
  To create the request you need to get transaction ID via `create_transaction/1` method.

  _Signed API request._

  [Example](https://indacoin.com/gw/payment_form?transaction_id=1154&partner=indacoin&cnfhash=Ny8zcXVWbCs5MVpGRFFXem44NW h5SE9xTitlajkydFpDTXhDOVMrOFdOOD0=)

  ## params

  Required request params:

    - _transaction_id_ :: integer
  """
  def transaction_link(transaction_id) do
    message = "#{partner_name()}_#{transaction_id}"

    signature =
      :crypto.hmac(:sha256, secret_key(), message)
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

  _Signed API request._

  ## Paging Through Results Using Offset and Limit

  - `limit=10` -> Returns the first 10 records.
  - `offset=5&limit=5` -> Returns records 6..10.
  - `offset=10` -> Returns records 11..61 (the default number of the returned records is 50).

  ## params

  All params are optional:

    - _user_id_ :: string
    - _tx_id_ :: string
    - _status_ :: string
    - _created_at_ :: integer / timestamp
    - _hash_ :: string
    - _cur_in_ :: string
    - _cur_out_ :: string
    - _amount_in_ :: decimal
    - _amount_out_ :: decimal
    - _target_address_ :: string
    - _limit_ :: integer
    - _offset_ :: integer
  """
  def transactions_history(params \\ %{}) do
    optional_params = ~w(
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
    )

    url = api_host() <> "api/exgw_getTransactions"

    body =
      take_params(params, optional_params)
      |> Jason.encode!()

    do_signed_request(url, body)
  end

  @doc """
  Retrieves transaction info by its id.

  _Signed API request._
  """
  def transaction(id) when is_integer(id) do
    url = api_host() <> "api/exgw_gettransactioninfo"

    body =
      %{transaction_id: id}
      |> Jason.encode!()

    do_signed_request(url, body)
  end

  @doc """
  Indacoin will send a callback to your application's exposed URL when a customer makes a payment.

  _While testing, you can accept all incoming callbacks, but in production, you'll need
  to verify the authenticity of incoming requests._

  ## params

  Required request params:

    - _indacoin_signature_ :: string
    - _indacoin_nonce_ :: integer
    - _user_id_ :: string
    - _tx_id_ :: integer
  """
  def valid_callback_signature?(indacoin_signature, indacoin_nonce, user_id, tx_id) do
    new_signature =
      "#{partner_name()}_#{user_id}_#{indacoin_nonce}_#{tx_id}"
      |> sign()
      |> Base.encode64()
      |> to_string()

    new_signature == to_string(indacoin_signature)
  end

  @doc """
  Fetches Indacoin API host from the application config.
  """
  def api_host,
    do: Application.fetch_env!(:indacoin, :api_host)

  @doc """
  Fetches Indacoin API key (a partner name) from the application config.
  """
  def partner_name,
    do: Application.fetch_env!(:indacoin, :partner_name)

  @doc """
  Fetches Indacoin API secret key from the application config.
  """
  def secret_key,
    do: Application.fetch_env!(:indacoin, :secret_key)

  def construct_signature(nonce \\ Enum.random(100_000..1_000_000)) do
    message = "#{partner_name()}_#{nonce}"
    %{nonce: nonce, value: sign(message)}
  end

  defp sign(message) do
    :crypto.hmac(:sha256, secret_key(), message)
    |> Base.encode64()
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

  # NOTE: Indacoin can be really slow... we have to specify big timeout value
  defp do_request(method, url, body \\ "", headers \\ [], recv_timeout \\ 20_000) do
    headers = Enum.into(headers, [{"Content-Type", "application/json"}])
    request = HTTPoison.request(method, url, body, headers, recv_timeout: recv_timeout)

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- request,
         {:ok, decoded} <- Jason.decode(body) do
      cond do
        is_bitstring(decoded) -> {:error, decoded}
        true -> {:ok, decoded}
      end
    else
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, status_code}

      {:error, error} ->
        {:error, error}
    end
  end

  defp missing_required_request_params(keys) do
    {:error, "Following request params must be provided: #{Enum.join(keys, ", ")}"}
  end
end
