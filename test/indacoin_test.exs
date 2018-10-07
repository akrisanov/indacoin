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

    test "returns an error if HTTP status is not 200", %{bypass: bypass} do
      Bypass.expect(bypass, &Plug.Conn.send_resp(&1, 429, ""))
      assert {:error, 429} == Indacoin.available_coins()
    end

    test "returns an error if can't parse JSON response", %{bypass: bypass} do
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

    test "with all available params returns full payment url", %{bypass: bypass} do
      assert {:ok, url} = Indacoin.forwarding_link(forwarding_link_valid_fixture())

      assert url ==
               "http://localhost:#{bypass.port}/gw/payment_form?" <>
                 "address=1J4hxz5vDTeBvZcb6BqLJugKbeEvMihrr1&" <>
                 "amount=59.99&cur_from=USD&cur_to=BTC&partner=elixir&user_id=test%40example.com"
    end

    test "with some optional params returns shorter payment url", %{bypass: bypass} do
      assert {:ok, url} = Indacoin.forwarding_link(forwarding_link_valid_fixture(%{"partner" => nil, "user_id" => nil}))

      assert url ==
               "http://localhost:#{bypass.port}/gw/payment_form?" <>
                 "address=1J4hxz5vDTeBvZcb6BqLJugKbeEvMihrr1&" <> "amount=59.99&cur_from=USD&cur_to=BTC"
    end
  end
end
