#!/usr/bin/env bash
# Quick test: bash check.sh your-service-xxxx.a.run.app
HOST="${1:?Usage: bash check.sh your-service.a.run.app}"
echo "Health:"; curl -s -m 10 "https://$HOST/health"
for P in / /vray /vless /vmess /trojan; do
  CODE=$(curl -s -m 10 -o /dev/null -w '%{http_code}' \
    -H 'Connection: Upgrade' -H 'Upgrade: websocket' \
    -H 'Sec-WebSocket-Version: 13' -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' \
    "https://$HOST$P")
  echo "$P -> HTTP $CODE  (101 = tunnel OK, 502/504 = VPS port closed or wrong)"
done
