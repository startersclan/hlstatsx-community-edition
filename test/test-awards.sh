#!/bin/sh
set -eu

docker exec -i $( docker compose ps -q awards) sh -c /awards.sh
