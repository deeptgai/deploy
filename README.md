# DeepTG deploy

Docker Swarm deployment files for `deeptgai/workspace`.

## Files

- `stack.yml` - Docker Swarm stack: Traefik, web, bot, worker, postgres+pgvector, redis, SeaweedFS S3 storage.
- `Makefile` - common deploy commands.
- `ENV.example` - environment template. Copy it to `ENV` and fill secrets.
- `scripts/install-ubuntu.sh` - fresh Ubuntu bootstrap script.

## Quick Start

```bash
cp ENV.example ENV
$EDITOR ENV

make login
make deploy
make storage-bootstrap
make ps
```

The web app and bot webhook are exposed through Traefik on origin HTTP port `80`.
Cloudflare terminates public HTTPS and proxies to Traefik over HTTP.
Set `DOMAIN`, `BOT_DOMAIN` and all Traefik settings in `ENV`; DNS/proxy is managed in Cloudflare.
Use `https://tgdeep.xyz` as `TELEGRAM_WEBHOOK_URL`; Telegram requires HTTPS for public webhooks even when Cloudflare talks to Traefik over origin HTTP. The stack routes `tgdeep.xyz/telegram/webhook` and `bot.tgdeep.xyz` to the same bot service.

## Useful Commands

```bash
make deploy       # deploy/update stack
make db-migrate   # apply Prisma migrations manually
make storage-bootstrap # create object storage bucket
make ps           # stack services
make logs-traefik # Traefik logs
make logs-web     # web logs
make logs-bot     # bot logs
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
make storage-bootstrap
```
