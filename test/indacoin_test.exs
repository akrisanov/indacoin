defmodule IndacoinTest do
  use ExUnit.Case, async: true
  doctest Indacoin

  import IndacoinFixtures

  setup do
    bypass = Bypass.open()
    Application.put_env(:indacoin, :api_host, "http://localhost:#{bypass.port}/")
    {:ok, bypass: bypass}
  end

  describe "available_coins/0" do
    @prebacked_payload Jason.encode!(indacoin_active_and_disabled_coins_fixture())
    @prebacked_response [bch_fixture(), eth_fixture()]

    test "retrive a list of all available coins sorted by name", %{bypass: bypass} do
      Bypass.expect(bypass, &Plug.Conn.send_resp(&1, 200, @prebacked_payload))
      assert {:ok, @prebacked_response} == Indacoin.available_coins()
    end

    test "returns an error when HTTP status is not 200", %{bypass: bypass} do
      Bypass.expect(bypass, &Plug.Conn.send_resp(&1, 429, ""))
      assert {:error, 429} == Indacoin.available_coins()
    end

    test "returns an error when can't parse JSON response", %{bypass: bypass} do
      Bypass.expect(bypass, &Plug.Conn.send_resp(&1, 200, "#{@prebacked_payload},"))
      {:error, error} = Indacoin.available_coins()
      assert error.__struct__ == Jason.DecodeError
    end
  end

  describe "forwarding_link/1" do
    @error_message "Following request params must be provided: cur_from, cur_to, amount, address"

    test "with empty request params returns an error" do
      assert {:error, desc} = Indacoin.forwarding_link(forwarding_link_empty_fixture())
      assert desc == @error_message
    end

    test "with any missing request param returns an error" do
      assert {:error, desc} = Indacoin.forwarding_link(forwarding_link_valid_fixture(%{"cur_from" => ""}))

      assert desc == @error_message
    end

    test "with all valid params returns a full payment url", %{bypass: bypass} do
      assert {:ok, url} = Indacoin.forwarding_link(forwarding_link_valid_fixture())

      assert url ==
               "http://localhost:#{bypass.port}/gw/payment_form?" <>
                 "address=1J4hxz5vDTeBvZcb6BqLJugKbeEvMihrr1&" <>
                 "amount=59.99&cur_from=USD&cur_to=BTC&partner=elixir&user_id=test%40example.com"
    end

    test "without optional params returns shorter payment url", %{bypass: bypass} do
      assert {:ok, url} = Indacoin.forwarding_link(forwarding_link_valid_fixture(%{"partner" => nil, "user_id" => ""}))

      assert url ==
               "http://localhost:#{bypass.port}/gw/payment_form?" <>
                 "address=1J4hxz5vDTeBvZcb6BqLJugKbeEvMihrr1&" <> "amount=59.99&cur_from=USD&cur_to=BTC"
    end
  end

  describe "transaction_price_request_url/1" do
    test "with all valid params returns a full request url", %{bypass: bypass} do
      assert {:ok, url} = Indacoin.transaction_price_request_url(transaction_price_fixture())

      assert url == "http://localhost:#{bypass.port}/api/GetCoinConvertAmount/USD/BTC/50.0/elixir/test@example.com"
    end

    test "without optional params returns shorter request url", %{bypass: bypass} do
      assert {:ok, url} =
               Indacoin.transaction_price_request_url(transaction_price_fixture(%{"partner" => nil, "user_id" => ""}))

      assert url == "http://localhost:#{bypass.port}/api/GetCoinConvertAmount/USD/BTC/50.0"
    end

    test "with any missing request param returns an error" do
      error_message = "Following request params must be provided: cur_from, cur_to, amount"

      assert {:error, desc} = Indacoin.transaction_price_request_url(transaction_price_fixture(%{"cur_from" => ""}))

      assert desc == error_message
    end
  end

  describe "transaction_price/1" do
    test "with valid params returns a transaction price", %{bypass: bypass} do
      prebacked_response = 0.00559900

      Bypass.expect(bypass, &Plug.Conn.send_resp(&1, 200, "#{prebacked_response}"))
      assert {:ok, prebacked_response} == Indacoin.transaction_price(transaction_price_fixture())
    end
  end
end
