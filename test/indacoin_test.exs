defmodule IndacoinTest do
  use ExUnit.Case, async: true
  doctest Indacoin

  import IndacoinFixtures

  setup do
    bypass = Bypass.open()
    Application.put_env(:indacoin, :api_host, "http://localhost:#{bypass.port}/")
    Application.put_env(:indacoin, :partner_name, "partner")
    Application.put_env(:indacoin, :secret_key, "secret")
    {:ok, bypass: bypass}
  end

  describe "api_host/0" do
    test "returns API host when an application environment has its value", %{bypass: bypass} do
      assert "http://localhost:#{bypass.port}/" == Indacoin.api_host()
    end

    test "raises an exception when an application environment doesn't include API host value" do
      Application.delete_env(:indacoin, :api_host)

      assert_raise ArgumentError, fn ->
        Indacoin.api_host()
      end
    end
  end

  describe "partner_name/0" do
    test "returns Indacoin API key (a partner name) when an application environment has its value" do
      assert "partner" == Indacoin.partner_name()
    end

    test "raises an exception when an application environment doesn't include API host value" do
      Application.delete_env(:indacoin, :partner_name)

      assert_raise ArgumentError, fn ->
        Indacoin.partner_name()
      end
    end
  end

  describe "secret_key/0" do
    test "returns Indacoin API secret key when an application environment has its value" do
      assert "secret" == Indacoin.secret_key()
    end

    test "raises an exception when an application environment doesn't include API host value" do
      Application.delete_env(:indacoin, :secret_key)

      assert_raise ArgumentError, fn ->
        Indacoin.secret_key()
      end
    end
  end

  describe "construct_signature/1" do
    test "returns API request signature along with the nonce" do
      assert %{nonce: 0, value: "qgH4bbykF3g3K/hkZCZJP/NjuGlr+gigbX6wz1BsYq8="} == Indacoin.construct_signature(0)
    end
  end

  describe "valid_callback_signature?/4" do
    @indacoin_signature "dTh2ZDhYb2xMYW5iMEltU2VkYkg4NlRCVTF1bjdUaExUUGRVd3pYMFA5RT0="
    @user_id "test@example.com"
    @transaction_id 123_456

    test "returns true when client signature is equal to indacoin signature" do
      indacoin_nonce = 78_901
      assert true == Indacoin.valid_callback_signature?(@indacoin_signature, indacoin_nonce, @user_id, @transaction_id)
    end

    test "returns false when client signature is not equal to indacoin signature" do
      indacoin_nonce = 1_234
      assert false == Indacoin.valid_callback_signature?(@indacoin_signature, indacoin_nonce, @user_id, @transaction_id)
    end
  end

  describe "available_coins/0" do
    @prebacked_payload Jason.encode!(active_and_disabled_coins_fixture())
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
      assert {:error, message} = Indacoin.forwarding_link(forwarding_link_empty_fixture())
      assert message == @error_message
    end

    test "with any missing request param returns an error" do
      assert {:error, message} = Indacoin.forwarding_link(forwarding_link_valid_fixture(%{"cur_from" => ""}))

      assert message == @error_message
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

      assert {:error, message} = Indacoin.transaction_price_request_url(transaction_price_fixture(%{"cur_from" => ""}))

      assert message == error_message
    end
  end

  describe "transaction_price/1" do
    @prebacked_response 0.00559900

    test "with valid params returns a transaction price", %{bypass: bypass} do
      Bypass.expect(bypass, &Plug.Conn.send_resp(&1, 200, "#{@prebacked_response}"))
      assert {:ok, @prebacked_response} == Indacoin.transaction_price(transaction_price_fixture())
    end
  end

  describe "create_transaction/1" do
    test "with valid params returns an ID of a drafted transaction", %{bypass: bypass} do
      prebacked_response = 12345

      Bypass.expect(bypass, &Plug.Conn.send_resp(&1, 200, "#{prebacked_response}"))
      assert {:ok, prebacked_response} == Indacoin.create_transaction(transaction_creation_fixture())
    end

    test "with any missing request param returns an error" do
      error_message = "Following request params must be provided: user_id, cur_in, cur_out, target_address, amount_in"

      assert {:error, message} = Indacoin.create_transaction(transaction_creation_fixture(%{"cur_out" => ""}))

      assert message == error_message
    end
  end

  describe "transaction_link/1" do
    test "returns a signed link (with API secret key) that forwards a user to the payment form", %{bypass: bypass} do
      url =
        "http://localhost:#{bypass.port}/gw/payment_form?transaction_id=12345&partner=partner&" <>
          "cnfhash=MTViTXZ3d1UybXNTRkNDdWpxTHE3NFJLSmk2dE1vOEllRjIvNCtZTmxuWT0%3D"

      assert url == Indacoin.transaction_link(12345)
    end
  end

  describe "transactions_history/1" do
    @prebacked_payload Jason.encode!([transaction_fixture()])
    @prebacked_response [transaction_fixture()]

    test "returns a list of Indacoin API partner's transactions", %{bypass: bypass} do
      Bypass.expect(bypass, &Plug.Conn.send_resp(&1, 200, @prebacked_payload))
      assert {:ok, @prebacked_response} == Indacoin.transactions_history(%{"user_id" => "test@example.com"})
    end
  end

  describe "transaction/1" do
    @prebacked_payload Jason.encode!(transaction_fixture())
    @prebacked_response transaction_fixture()

    test "returns transaction info by its id", %{bypass: bypass} do
      Bypass.expect(bypass, &Plug.Conn.send_resp(&1, 200, @prebacked_payload))
      assert {:ok, @prebacked_response} == Indacoin.transaction(123_456)
    end
  end
end
