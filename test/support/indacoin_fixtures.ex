defmodule IndacoinFixtures do
  def eth_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      "cur_id" => 248,
      "ext_market" => 2,
      "ext_market_id" => 0,
      "txfee" => 0.006,
      "short_name" => "ETH",
      "name" => "Ethereum",
      "cointype" => "ETH",
      "imageurl" => "/api/coinimage/ETH/",
      "availableSupply" => "99872465",
      "price" => "0.03358030",
      "isActive" => attrs[:isActive] || true,
      "minTradeSize" => 0.00346548,
      "tag" => false
    })
  end

  def bch_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      "cur_id" => 385,
      "ext_market" => 2,
      "ext_market_id" => 0,
      "txfee" => 0.00100000,
      "short_name" => "BCH",
      "name" => "Bitcoin Cash",
      "cointype" => "BITCOIN",
      "imageurl" => "/api/coinimage/BCH/",
      "availableSupply" => "9612454",
      "price" => "0.07824501",
      "isActive" => true,
      "minTradeSize" => 0.00157040,
      "tag" => false
    })
  end

  def ntrn_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      "cur_id" => 231,
      "ext_market" => 2,
      "ext_market_id" => 0,
      "txfee" => 0.02000000,
      "short_name" => "NTRN",
      "name" => "Neutron",
      "cointype" => "BITCOIN",
      "imageurl" => "/api/coinimage/NTRN/",
      "availableSupply" => "36070053",
      "price" => "",
      "isActive" => false,
      "minTradeSize" => -1.0,
      "tag" => false
    })
  end

  def indacoin_active_and_disabled_coins_fixture() do
    [
      eth_fixture(),
      bch_fixture(),
      ntrn_fixture()
    ]
  end

  def forwarding_link_valid_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      "partner" => "elixir",
      "cur_from" => "USD",
      "cur_to" => "BTC",
      "amount" => 59.99,
      "address" => "1J4hxz5vDTeBvZcb6BqLJugKbeEvMihrr1",
      "user_id" => "test@example.com"
    })
  end

  def forwarding_link_empty_fixture() do
    %{
      "partner" => "",
      "cur_from" => "",
      "cur_to" => "",
      "amount" => nil,
      "address" => "",
      "user_id" => ""
    }
  end

  def transaction_price_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      "cur_from" => "USD",
      "cur_to" => "BTC",
      "amount" => 50.0,
      "partner" => "elixir",
      "user_id" => "test@example.com"
    })
  end
end
