# DeepTG deploy

Docker Swarm deployment files for `deeptgai/workspace`.

## Files

- `stack.yml` - Docker Swarm stack: web, worker, postgres+pgvector, redis.
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

The web app is exposed on `APP_PORT`, default `3000`.

## Useful Commands

```bash
make deploy       # deploy/update stack
make db-push      # apply Prisma schema to Postgres
make ps           # stack services
make logs-web     # web logs
make logs-worker  # worker logs
make rm           # remove stack
```

## Fresh Ubuntu Install

From this directory:

```bash
sudo ./scripts/install-ubuntu.sh
```

Then edit `/opt/deeptg/deploy/ENV` and run:

```bash
cd /opt/deeptg/deploy
make login
make deploy
make db-push
```
