#!/bin/bash

# Fetch Bitcoin price in EUR using CoinGecko API
price=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=eur" | jq -r '.bitcoin.eur')

if [ -z "$price" ] || [ "$price" = "null" ]; then
    echo "BTC: N/A"
else
    # Format with thousand separators
    printf "BTC: €%'.0f" "$price"
fi
