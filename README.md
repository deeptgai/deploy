# DeepTG deploy

Docker Swarm deployment files for `deeptgai/workspace`.

## Files

- `stack.yml` - Docker Swarm stack: Traefik, web, worker, postgres+pgvector, redis.
- `Makefile` - common deploy commands.
- `ENV.example` - environment template. Copy it to `ENV` and fill secrets.
- `scripts/install-ubuntu.sh` - fresh Ubuntu bootstrap script.

## Quick Start

```bash
cp ENV.example ENV
$EDITOR ENV

make login
make deploy
make db-push
make ps
```

The web app is exposed through Traefik on ports `80` and `443`.
Set `DOMAIN` and all Traefik settings in `ENV`; DNS/proxy is managed in Cloudflare.

## Useful Commands

```bash
make deploy       # deploy/update stack
make db-push      # apply Prisma schema to Postgres
make ps           # stack services
make logs-traefik # Traefik logs
make logs-web     # web logs
make logs-worker  # worker logs
make rm           # remove stack
```

## Fresh Ubuntu Install

From this directory:

```bash
sudo ./scripts/install-ubuntu.sh
```

Then edit `/opt/deploy/ENV` and run:

```bash
cd /opt/deploy
make login
make deploy
make db-push
```
