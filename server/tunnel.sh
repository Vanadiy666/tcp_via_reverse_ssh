#!/bin/sh
set -eu
umask 077

: "${CLIENT_ADDRESS:?Set CLIENT_ADDRESS in server/.env}"
: "${CLIENT_HOST_PUBLIC_KEY:?Set CLIENT_HOST_PUBLIC_KEY in server/.env}"
CLIENT_SSH_PORT=${CLIENT_SSH_PORT:-2222}
TARGET_HOST=${TARGET_HOST:-host.docker.internal}
TARGET_PORT=${TARGET_PORT:-8080}

# Restrict input to DNS names / IPv4 addresses; do not accept SSH options or newlines.
for address in "$CLIENT_ADDRESS" "$TARGET_HOST"; do
    case "$address" in
        ''|-*|*[!a-zA-Z0-9_.-]*) echo "Invalid hostname: $address" >&2; exit 1 ;;
    esac
done
for port in "$CLIENT_SSH_PORT" "$TARGET_PORT"; do
    case "$port" in
        ''|*[!0-9]*) echo "Invalid port: $port" >&2; exit 1 ;;
    esac
    if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo "Port outside 1..65535: $port" >&2
        exit 1
    fi
done
if [ ! -r /keys/id_ed25519 ]; then
    echo 'Key missing or unreadable. Run: docker compose run --rm keygen' >&2
    exit 1
fi

printf '%s\n' "$CLIENT_HOST_PUBLIC_KEY" > /tmp/host.pub
ssh-keygen -l -f /tmp/host.pub > /dev/null
printf '[%s]:%s %s\n' "$CLIENT_ADDRESS" "$CLIENT_SSH_PORT" "$CLIENT_HOST_PUBLIC_KEY" > /tmp/known_hosts

export AUTOSSH_GATETIME=0 AUTOSSH_POLL=10
exec autossh -M 0 -N -T -F /dev/null \
    -i /keys/id_ed25519 \
    -p "$CLIENT_SSH_PORT" \
    -o BatchMode=yes \
    -o IdentitiesOnly=yes \
    -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile=/tmp/known_hosts \
    -o GlobalKnownHostsFile=/dev/null \
    -o HostKeyAlias="[$CLIENT_ADDRESS]:$CLIENT_SSH_PORT" \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o ConnectTimeout=10 \
    -o ExitOnForwardFailure=yes \
    -R "0.0.0.0:18080:$TARGET_HOST:$TARGET_PORT" \
    "tunnel@$CLIENT_ADDRESS"
