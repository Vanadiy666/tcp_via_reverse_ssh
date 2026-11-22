**English** | [Русский](README.ru.md)

# TCP over reverse SSH

Server connects to Client over SSH. Requests to `Client:18080` reach the application on Server.
Both hosts need Docker and Docker Compose v2.

## Setup and startup

1. Copy `client/` to Client and `server/` to Server.
2. Run these commands in the corresponding directory **on each host**:

   ```bash
   cp .env-example .env
   docker compose run --rm keygen
   ```

   This creates a key in `./keys` and prints its public key.

3. Fill in `.env`:

   | File | Variable | Value |
   |---|---|---|
   | `client/.env` | `SERVER_PUBLIC_KEY` | Public key from Server |
   | `server/.env` | `CLIENT_HOST_PUBLIC_KEY` | Public key from Client |
   | `server/.env` | `CLIENT_ADDRESS` | Client DNS name or IPv4 address reachable from Server |

   Also set `TARGET_HOST` and `TARGET_PORT` in `server/.env` to your application's address and port (see below).

   Paste each complete public key in quotes: `"ssh-ed25519 AAAA..."`. Keep private keys on their original hosts.

4. Start services on each host:

   ```bash
   docker compose up -d
   ```

5. Connect to `<Client-address>:18080` using your application's protocol.
   Client must accept connections on TCP port `2222` from Server and port `18080` from application users.

## Your application

Set `TARGET_HOST` and `TARGET_PORT` in `server/.env`:

- **Container:** service name and port, for example `backend` and `8080`.
  The application and `tunnel` must share a Docker network.
- **Server host:** `host.docker.internal` and the application's port.
  On Linux, the application must listen on an address reachable from Docker, not only `127.0.0.1`.

## Ports and maintenance

- Published application port: `FORWARD_PORT` in `client/.env`.
- Access from Client itself only: `FORWARD_BIND_ADDRESS=127.0.0.1` (default: all interfaces).
- When changing `SSH_PORT` on Client, update `CLIENT_SSH_PORT` on Server.
- After editing `.env`: `docker compose up -d`.
- Logs: `docker compose logs -f`.
- Stop: `docker compose down`.

Keys and state are stored in `keys/` and `client/config/`. Do not delete or publish these directories.
