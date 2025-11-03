#!/bin/bash

# Fetch weather data from wttr.in
# You can customize the location by setting the WEATHER_LOCATION environment variable
# Example: export WEATHER_LOCATION="London" in your shell config

LOCATION="${WEATHER_LOCATION:-}"  # Empty means automatic location detection

# Fetch weather data with custom format
# %l = location name
# %c = weather condition (icon)
# %t = temperature
# %C = weather condition text
WEATHER_DATA=$(curl -sf "wttr.in/${LOCATION}?format=%l+%c+%t")

if [ -z "$WEATHER_DATA" ]; then
    echo '{"text":"󰖕 N/A","tooltip":"Weather data unavailable"}'
    exit 0
fi

# Get detailed weather info for tooltip
WEATHER_TOOLTIP=$(curl -sf "wttr.in/${LOCATION}?format=%l:+%C,+Feels+like+%f,+Wind:+%w,+Humidity:+%h")

if [ -z "$WEATHER_TOOLTIP" ]; then
    WEATHER_TOOLTIP="$WEATHER_DATA"
fi

# Output JSON format for waybar
echo "{\"text\":\"$WEATHER_DATA\",\"tooltip\":\"$WEATHER_TOOLTIP\"}"
