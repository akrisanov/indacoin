# Indacoin

[![CircleCI](https://circleci.com/gh/akrisanov/indacoin.svg?style=svg)](https://circleci.com/gh/akrisanov/indacoin)
[![Coverage Status](https://coveralls.io/repos/github/akrisanov/indacoin/badge.svg?branch=master)](https://coveralls.io/github/akrisanov/indacoin?branch=master)

An Elixir interface to the Indacoin API.

## Installation

Add the package to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:indacoin, "~> 1.0.1"}
  ]
end
```

and run

```bash
mix deps.get
```

## Usage

Set your API credentials if you do authenticated requests:

```elixir
config :indacoin,
  partner_name: "YOUR_INDACOIN_PARTNER_NAME",
  secret_key: "YOUR_INDACOIN_SECRET_KEY"
```

## Contributing

Contributions to Gixy are always welcome! You can help us in different ways:

* Open an issue with suggestions for improvements and errors you're facing;
* Fork this repository and submit a pull request;
* Improve the documentation.

## Copyright

Copyright (C) 2018 Andrey Krisanov. The Package is licensed and distributed under the MIT license.
