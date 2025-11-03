#!/bin/bash

# Fetch EUR/HUF exchange rate using frankfurter.app API
rate=$(curl -s "https://api.frankfurter.app/latest?from=EUR&to=HUF" | jq -r '.rates.HUF')

if [ -z "$rate" ] || [ "$rate" = "null" ]; then
    echo "EUR/HUF: N/A"
else
    # Format to 2 decimal places
    printf "EUR/HUF: %.2f" "$rate"
fi
