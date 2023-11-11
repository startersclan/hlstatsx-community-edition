#!/bin/sh
set -eu

docker exec -i $( docker compose ps -q heatmaps) php /heatmaps/generate.php
