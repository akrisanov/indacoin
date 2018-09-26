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
    @prebacked_response [coin_fixture(), coin_fixture()]
    @prebacked_payload Poison.encode!(indacoin_active_and_disabled_coins_fixture())

    test "retrive a list of all available coins", %{bypass: bypass} do
      Bypass.expect(bypass, &Plug.Conn.send_resp(&1, 200, @prebacked_payload))
      assert {:ok, @prebacked_response} == Indacoin.available_coins()
    end

    test "returns an error if HTTP status is not 200", %{bypass: bypass} do
      Bypass.expect(bypass, &Plug.Conn.send_resp(&1, 429, ""))
      assert {:error, 429} == Indacoin.available_coins()
    end

    test "returns an error if can't parse JSON response", %{bypass: bypass} do
      Bypass.expect(bypass, &Plug.Conn.send_resp(&1, 200, "#{@prebacked_payload},"))

      assert {:error, {:invalid, ",", 1269}} == Indacoin.available_coins()
    end
  end

  describe "forwarding_link/1" do
    @partner "elixir"
    @price_currency "USD"
    @receive_currency "BTC"
    @price_amount 59.99
    @receive_btc_address "1J4hxz5vDTeBvZcb6BqLJugKbeEvMihrr1"
    @user_id "test@example.com"
    @error_message "Following request params must be provided: partner, cur_from, cur_to, amount, address, user_id"

    test "with required fields returns payment url", %{bypass: bypass} do
      assert {:ok, url} =
               Indacoin.forwarding_link(
                 partner: @partner,
                 cur_from: @price_currency,
                 cur_to: @receive_currency,
                 amount: @price_amount,
                 address: @receive_btc_address,
                 user_id: @user_id
               )

      assert url ==
               "http://localhost:#{bypass.port}/gw/payment_form?" <>
                 "partner=elixir&cur_from=USD&cur_to=BTC&amount=59.99&" <>
                 "address=1J4hxz5vDTeBvZcb6BqLJugKbeEvMihrr1&user_id=test%40example.com"
    end

    test "with empty request params returns an error" do
      assert {:error, desc} =
               Indacoin.forwarding_link(
                 partner: "",
                 cur_from: "",
                 cur_to: "",
                 amount: "",
                 address: "",
                 user_id: ""
               )

      assert desc == @error_message
    end

    test "with any missing request param returns an error" do
      assert {:error, desc} =
               Indacoin.forwarding_link(
                 partner: @partner,
                 cur_from: @price_currency,
                 cur_to: @receive_currency,
                 amount: @price_amount,
                 user_id: @user_id
               )

      assert desc == @error_message
    end
  end
end
