#!/usr/bin/env bash
# Fetches current week's offers for Netto, REMA 1000, Lidl from the public Tjek API
# and writes a trimmed offers.json for the Coachway recipe routine.
set -euo pipefail
TMP=$(mktemp)
echo '[]' > "$TMP"
fetch_store() {
  local store="$1" id="$2"
  curl -fsS "https://squid-api.tjek.com/v2/offers?dealer_ids=${id}&country_id=DK&limit=100" \
    | jq --arg s "$store" '[.[] | {heading, price: .pricing.price, store: $s, run_from, run_till}]' > "/tmp/offers_${id}.json"
  jq -s '.[0] + .[1]' "$TMP" "/tmp/offers_${id}.json" > "${TMP}.new" && mv "${TMP}.new" "$TMP"
}
fetch_store "Netto" "9ba51"
fetch_store "REMA 1000" "11deC"
fetch_store "Lidl" "71c90"
jq -n --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --slurpfile offers "$TMP" \
  '{fetched_at: $ts, source: "squid-api.tjek.com", offers: $offers[0]}' > offers.json
echo "Wrote offers.json with $(jq '.offers | length' offers.json) offers"
