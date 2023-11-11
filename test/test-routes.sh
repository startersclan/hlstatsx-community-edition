#!/bin/sh
set -eu

echo "[test-routes]"
URLS="
http://web/ 302
http://web/css/spinner.gif 200
http://web/hlstatsimg/ajax.gif 200
http://web/includes/ 401
http://web/pages/ 401
http://web/pages/.htaccess 401
http://web/styles/classic.css 200
http://web/updater/ 401
http://web/autocomplete.php 200
http://web/config.php 401
http://web/hlstats.php 200
http://web/index.php 302
http://web/ingame.php 200
http://web/show_graph.php 200
http://web/sig.php 200
http://web/status.php 200
http://web/trend_graph.php 200
"
echo "$URLS" | awk NF | while read -r i j; do
    if wget -q -SO- "$i" 2>&1 | grep "HTTP/1.1 $j " > /dev/null; then
        echo "PASS: $i"
    else
        echo "FAIL: $i"
        exit 1
    fi
done
