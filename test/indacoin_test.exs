defmodule IndacoinTest do
  use ExUnit.Case
  doctest Indacoin

  describe "forwarding_link/1" do
    @partner "elixir"
    @price_currency "USD"
    @receive_currency "BTC"
    @price_amount 59.99
    @receive_btc_address "1J4hxz5vDTeBvZcb6BqLJugKbeEvMihrr1"
    @user_id "test@example.com"
    @error_message "Following request params must be provided: partner, cur_from, cur_to, amount, address, user_id"

    test "with required fields" do
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
               "https://indacoin.com/gw/payment_form?" <>
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

    test "with one missing request param returns an error" do
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
