#!/bin/bash

# News Ticker Script for Waybar
# Fetches headlines from RSS feeds and displays them with navigation

# Configuration
RSS_FEEDS=(
  "https://telex.hu/rss/archivum?filters=%7B%22parentId%22%3A%5B%22null%22%5D%7D&perPage=5"
  "https://prohardver.hu/hirfolyam/anyagok/kategoria/it_cafe/rss.xml"
  "https://www.portfolio.hu/rss/all.xml"
  )

HEADLINES_FILE="/tmp/waybar-news-headlines"
INDEX_FILE="/tmp/waybar-news-index"
CACHE_DURATION=180  # 30 minutes in seconds
TICKER_WIDTH=90  # Maximum characters to display

# Handle navigation
ACTION="${1:-display}"

# Check if headlines need to be refreshed (but not during navigation or opening)
NEED_REFRESH=false
if [ "$ACTION" = "display" ]; then
    if [ ! -f "$HEADLINES_FILE" ]; then
        NEED_REFRESH=true
    elif [ -f "$HEADLINES_FILE" ]; then
        CACHE_AGE=$(($(date +%s) - $(stat -c %Y "$HEADLINES_FILE")))
        if [ $CACHE_AGE -gt $CACHE_DURATION ]; then
            NEED_REFRESH=true
        fi
    fi
elif [ ! -f "$HEADLINES_FILE" ]; then
    # If headlines file doesn't exist and we're navigating/opening, fetch it once
    NEED_REFRESH=true
fi

# Function to fetch and parse RSS feed
fetch_headlines() {
    local feed_url="$1"

    # Fetch RSS feed
    local rss_content=$(curl -s --max-time 10 "$feed_url")

    # Extract items (skip the first title which is the feed title)
    echo "$rss_content" | \
        awk '/<item>/,/<\/item>/' | \
        awk '
            /<title>/ {
                match($0, /<title>(.*)<\/title>/, arr)
                title = arr[1]
                gsub(/<!\[CDATA\[/, "", title)
                gsub(/\]\]>/, "", title)
                gsub(/&amp;/, "\\&", title)
                gsub(/&lt;/, "<", title)
                gsub(/&gt;/, ">", title)
                gsub(/&quot;/, "\"", title)
                gsub(/&#39;/, "'\''", title)
                gsub(/&apos;/, "'\''", title)
            }
            /<link>/ {
                match($0, /<link>(.*)<\/link>/, arr)
                link = arr[1]
                if (title && link) {
                    print title "\t" link
                    title = ""
                    link = ""
                }
            }
        ' | head -n 10
}

# Fetch headlines if needed
if [ "$NEED_REFRESH" = true ]; then
    ALL_HEADLINES=""
    for feed in "${RSS_FEEDS[@]}"; do
        headlines=$(fetch_headlines "$feed")
        if [ -n "$headlines" ]; then
            ALL_HEADLINES="$ALL_HEADLINES$headlines"$'\n'
        fi
    done

    # If no headlines were fetched, show error
    if [ -z "$ALL_HEADLINES" ]; then
        echo '{"text": "󰎕 No news available", "tooltip": "Failed to fetch news feeds", "class": "error"}'
        exit 0
    fi

    # Save headlines to file (title\turl per line)
    echo "$ALL_HEADLINES" | grep -v '^$' > "$HEADLINES_FILE"

    # Reset index to 0
    echo "0" > "$INDEX_FILE"
fi

# Get current index
if [ ! -f "$INDEX_FILE" ]; then
    echo "0" > "$INDEX_FILE"
fi
CURRENT_INDEX=$(cat "$INDEX_FILE")

# Get total number of headlines
TOTAL_HEADLINES=$(wc -l < "$HEADLINES_FILE")

# Handle navigation actions
if [ "$ACTION" = "next" ]; then
    CURRENT_INDEX=$((CURRENT_INDEX + 1))
    if [ $CURRENT_INDEX -ge $TOTAL_HEADLINES ]; then
        CURRENT_INDEX=0
    fi
    echo "$CURRENT_INDEX" > "$INDEX_FILE"
elif [ "$ACTION" = "prev" ]; then
    CURRENT_INDEX=$((CURRENT_INDEX - 1))
    if [ $CURRENT_INDEX -lt 0 ]; then
        CURRENT_INDEX=$((TOTAL_HEADLINES - 1))
    fi
    echo "$CURRENT_INDEX" > "$INDEX_FILE"
elif [ "$ACTION" = "open" ]; then
    # Get current line (title\turl)
    LINE=$(sed -n "$((CURRENT_INDEX + 1))p" "$HEADLINES_FILE")
    URL=$(echo "$LINE" | cut -f2)
    if [ -n "$URL" ]; then
        xdg-open "$URL" &
    fi
    exit 0
fi

# Get current headline (1-indexed for sed)
LINE=$(sed -n "$((CURRENT_INDEX + 1))p" "$HEADLINES_FILE")
HEADLINE=$(echo "$LINE" | cut -f1)
URL=$(echo "$LINE" | cut -f2)

# Extract domain from URL
DOMAIN=$(echo "$URL" | sed 's|https\?://||' | sed 's|/.*||')

# Format with domain prefix
DISPLAY_TEXT="$DOMAIN: $HEADLINE"

# Truncate if too long
if [ ${#DISPLAY_TEXT} -gt $TICKER_WIDTH ]; then
    MAX_LEN=$((TICKER_WIDTH - 3))  # Leave room for ellipsis
    DISPLAY_TEXT="${DISPLAY_TEXT:0:$MAX_LEN}..."
fi

# Create tooltip with position info and all headlines
TOOLTIP=$(printf "Article %d/%d\nClick to open article\nScroll to navigate\nAll headlines:\n%s" \
    "$((CURRENT_INDEX + 1))" \
    "$TOTAL_HEADLINES" \
    "$(cat "$HEADLINES_FILE" | cut -f1 | sed 's/^/• /')")

# Create JSON output
JSON_OUTPUT=$(jq -nc \
    --arg text "󰎕 $DISPLAY_TEXT" \
    --arg tooltip "$TOOLTIP" \
    '{text: $text, tooltip: $tooltip, class: "news-ticker"}')

# Output to waybar
echo "$JSON_OUTPUT"
