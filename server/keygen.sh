#!/bin/sh
set -eu
umask 077
mkdir -p /keys
if [ ! -f /keys/id_ed25519 ]; then
    ssh-keygen -q -t ed25519 -N '' -f /keys/id_ed25519
fi
ssh-keygen -y -f /keys/id_ed25519 > /keys/id_ed25519.pub
chown 1000:1000 /keys /keys/id_ed25519 /keys/id_ed25519.pub
chmod 700 /keys
chmod 600 /keys/id_ed25519
chmod 644 /keys/id_ed25519.pub
printf '\nPublic key (copy this line to the other node):\n'
cat /keys/id_ed25519.pub
