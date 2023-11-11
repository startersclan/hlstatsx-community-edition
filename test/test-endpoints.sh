#!/bin/sh
set -eu

echo "[test-endpoints]"
ENDPOINTS="
web.example.com 200
phpmyadmin.example.com 200
"
command -v curl || apk add --no-cache curl
echo "$ENDPOINTS" | awk NF | while read -r i j; do
    if curl --head -skL http://$i --resolve $i:80:127.0.0.1 --resolve $i:443:127.0.0.1 2>&1 | grep "^HTTP/2 $j " > /dev/null; then
        echo "PASS: $i"
    else
        echo "FAIL: $i"
        exit 1
    fi
done
