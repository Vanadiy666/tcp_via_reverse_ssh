#!/bin/sh
set -eu

: "${TUNNEL_PUBLIC_KEY:?Set SERVER_PUBLIC_KEY in client/.env}"
if [ ! -s /keys/id_ed25519 ]; then
    echo 'Host key missing. Run: docker compose run --rm keygen' >&2
    exit 1
fi

# Replace authorized_keys on every start: removing a key from .env revokes it.
printf '%s\n' "$TUNNEL_PUBLIC_KEY" > /config/.ssh/authorized_keys
ssh-keygen -l -f /config/.ssh/authorized_keys > /dev/null
chown tunnel:tunnel /config/.ssh/authorized_keys
chmod 600 /config/.ssh/authorized_keys

# The service passes these host key files to sshd explicitly.
cp /keys/id_ed25519 /config/ssh_host_keys/ssh_host_ed25519_key
ssh-keygen -y -f /keys/id_ed25519 > /config/ssh_host_keys/ssh_host_ed25519_key.pub
chown tunnel:tunnel /config/ssh_host_keys/ssh_host_ed25519_key*
chmod 600 /config/ssh_host_keys/ssh_host_ed25519_key
chmod 644 /config/ssh_host_keys/ssh_host_ed25519_key.pub

# This dedicated SSH server permits only the fixed reverse TCP listener.
cat > /config/sshd/sshd_config <<'CONFIG'
Port 2222
ListenAddress 0.0.0.0
PidFile none
AuthorizedKeysFile /config/.ssh/authorized_keys
PubkeyAuthentication yes
AuthenticationMethods publickey
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitEmptyPasswords no
PermitRootLogin no
AllowUsers tunnel
AllowTcpForwarding remote
GatewayPorts clientspecified
PermitListen 0.0.0.0:18080
PermitOpen none
AllowStreamLocalForwarding no
AllowAgentForwarding no
X11Forwarding no
PermitTTY no
PermitTunnel no
PermitUserRC no
MaxSessions 0
ForceCommand /bin/false
ClientAliveInterval 30
ClientAliveCountMax 3
LoginGraceTime 30
LogLevel VERBOSE
CONFIG
chown root:tunnel /config/sshd/sshd_config
chmod 640 /config/sshd/sshd_config
