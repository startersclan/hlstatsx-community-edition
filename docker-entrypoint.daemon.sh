#!/bin/sh

output() {
    echo "$( date '+%Y-%m-%d %H:%M:%S' ) $1";
}

###############################################################################
# Environmnet variables expanded fomr Docker Secrets
# Modified to use the syntax: DOCKER-SECRET:my_docker_secret
# from: https://gist.github.com/bvis/b78c1e0841cfd2437f03e20c1ee059fe#file-env_secrets_expand-sh
# from: https://medium.com/@basi/docker-environment-variables-expanded-from-secrets-8fa70617b3bc
#

: ${ENV_SECRETS_DIR:=/run/secrets}

env_secret_debug()
{
    if [ ! -z "$ENV_SECRETS_DEBUG" ]; then
        echo -e "\033[1m$@\033[0m"
    fi
}

# usage: env_secret_expand VAR
#    ie: env_secret_expand 'XYZ_DB_PASSWORD'
# (will check for "$XYZ_DB_PASSWORD" variable value for a placeholder that defines the
#  name of the docker secret to use instead of the original value. For example:
# XYZ_DB_PASSWORD={{DOCKER-SECRET:my-db.secret}}
env_secret_expand() {
    var="$1"
    eval val=\$$var
    if secret_name=$(expr match "$val" "DOCKER-SECRET:\([^}]\+\)$"); then
        secret="${ENV_SECRETS_DIR}/${secret_name}"
        env_secret_debug "Secret file for $var: $secret"
        if [ -f "$secret" ]; then
            val=$(cat "${secret}")
            export "$var"="$val"
            env_secret_debug "Expanded variable: $var=$val"
        else
            env_secret_debug "Secret file does not exist! $secret"
        fi
    fi
}

env_secrets_expand() {
    for env_var in $(printenv | cut -f1 -d"=")
    do
        env_secret_expand $env_var
    done

    if [ ! -z "$ENV_SECRETS_DEBUG" ]; then
        echo -e "\n\033[1mExpanded environment variables\033[0m"
        printenv
    fi
}

env_secrets_expand

###############################################################################

# Generate the full command line

# Note: As of hlxce 1.6.19, hlstats.pl's --configfile argument does not take effect.
# To fix this, find this line in hlstats.pl:
#    if ($configfile && -r $configfile) {
# Add this code line before it:
#   setOptionsConf(%copts);
# That should fix hlstats.pl's --configfile argument issue.
[ ! -z "${CONFIG_FILE}" ] && set "$@" "--configfile=${CONFIG_FILE}"

if [ ! -z "${LOG_LEVEL}" ]; then
    if [ "${LOG_LEVEL}" = '0' ]; then
        set "$@" "-n"
    elif [ "${LOG_LEVEL}" = '1' ]; then
        set "$@" "-d"
    elif [ "${LOG_LEVEL}" = '2' ]; then
        set "$@" "-dd"
    else
        :
    fi
fi
[ ! -z "${MODE}" ] && set "$@" "--db-host=${MODE}"
[ ! -z "${LISTEN_IP}" ] && set "$@" "--ip=${LISTEN_IP}"
[ ! -z "${LISTEN_PORT}" ] && set "$@" "--ip=${LISTEN_PORT}"
[ ! -z "${DB_HOST}" ] && set "$@" "--db-host=${DB_HOST}"
[ ! -z "${DB_NAME}" ] && set "$@" "--db-name=${DB_NAME}"
[ ! -z "${DB_USER}" ] && set "$@" "--db-username=${DB_USER}"
[ ! -z "${DB_PASSWORD}" ] && set "$@" "--db-password=${DB_PASSWORD}"
[ "${DNS_RESOLVE_IP}" = 'false' ] && set "$@" "--nodns-resolveip"
[ ! -z "${DNS_RESOLVE_IP_TIMEOUT}" ] && set "$@" "--dns-timeout=${DNS_RESOLVE_IP_TIMEOUT}"
[ ! -z "${LISTEN_IP}" ] && set "$@" "--db-password=${LISTEN_IP}"
[ ! -z "${LISTEN_PORT}" ] && set "$@" "--db-password=${LISTEN_PORT}"
[ "${RCON}" = 'false' ] && set "$@" "--norcon"
[ "${STDIN}" = 'true' ] && set "$@" "--stdin"
[ ! -z "${STDIN_SERVER_IP}" ] && set "$@" "--server-ip=${STDIN_SERVER_IP}"
[ ! -z "${STDIN_SERVER_PORT}" ] && set "$@" "--server-port=${STDIN_SERVER_PORT}"
[ "${USE_LOG_TIMESTAMP}" = 'true' ] && set "$@" "--timestamp"
# [ ! -z "${EVENT_QUEUE_SIZE}" ] && set "$@" "--event-queue-size=${EVENT_QUEUE_SIZE}"

if [ ! -z "${ECHO_ENVIRONMENT}" ]; then
    output "Environment: \n$( env )"
    commandline="$@"
    output "Command line: $commandline"
fi

# Download the GeoLite / GeoLite2 DB
#[ ! -f install_binary_GeoLite.sh ] && perl install_binary_GeoLite.sh
#[ ! -f install_binary_GeoLite2.sh ] && perl install_binary_GeoLite2.sh

output "Starting daemon..."
set -x
# Run script
exec "$@"
