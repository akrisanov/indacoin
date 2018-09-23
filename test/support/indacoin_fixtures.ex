defmodule IndacoinFixtures do
  def coin_fixture(attrs \\ %{}) do
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

  def indacoin_active_and_disabled_coins_fixture() do
    [
      coin_fixture(),
      coin_fixture(),
      coin_fixture(%{"isActive" => false}),
      coin_fixture(%{"isActive" => false}),
      coin_fixture(%{"isActive" => false})
    ]
  end
end
