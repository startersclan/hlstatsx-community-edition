#!/bin/sh
set -eu

TEST=${1:-} # Test environment
UP=${2:-} # Whether to docker compose up and down the test stack
CACHE=${3:-} # Whether to override with docker-compose.build.yml

# Validation and normalization
if ! echo "$TEST" | grep -E '^(dev|prod)$' > /dev/null; then
    echo "Specify TEST as the first argument. E.g. 'dev', 'prod'"
    exit 1
fi
if [ -n "$CACHE" ]; then
    CACHE='-f docker-compose.build.yml'
fi

SCRIPT_DIR=$( cd "$( dirname "$0" )" && pwd )
ERR=
setup_test() {
    cd "$SCRIPT_DIR"
    docker compose up -d
    if [ -n "$UP" ]; then
        setup
    fi
    run
}
cleanup_test() {
    ERR=$?
    if [ -n "$UP" ]; then
        cleanup
    fi
    docker compose stop
    if [ -z "$ERR" ] || [ "$ERR" = 0 ]; then
        echo "All tests succeeded"
    else
        echo "Some tests failed"
        echo "Exit code: $ERR"
        exit "$ERR"
    fi
}
trap cleanup_test INT TERM EXIT

echo "Testing..."
if [ "$TEST" = 'dev' ]; then
    setup() {
        if [ -n "$CACHE" ]; then
            CACHE='-f docker-compose.build.yml'
        fi
        (cd .. && docker compose -f docker-compose.yml $CACHE up --build -d)
    }
    run() {
        docker exec $( docker compose ps -q test-container-networking ) ./test-ready.sh
        docker exec $( docker compose ps -q test-container-networking ) ./test-routes.sh
        ./test-awards.sh
        ./test-heatmaps.sh
    }
    cleanup() {
        (cd .. && docker compose -f docker-compose.yml $CACHE stop)
    }
fi
if [ "$TEST" = 'prod' ]; then
    setup() {
        if [ -n "$CACHE" ]; then
            CACHE='-f docker-compose.example.build.yml'
        fi
        (cd .. && docker compose -f docker-compose.example.yml $CACHE up --build -d)
    }
    run() {
        docker exec $( docker compose ps -q test-container-networking ) ./test-ready.sh
        docker exec $( docker compose ps -q test-container-networking ) ./test-routes.sh
        ./test-awards.sh
        ./test-heatmaps.sh
        docker exec $( docker compose ps -q test-host-networking ) ./test-endpoints.sh
    }
    cleanup() {
        (cd .. && docker compose -f docker-compose.example.yml $CACHE stop)
    }
fi
setup_test
