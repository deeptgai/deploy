# Deploy Agent Notes

Use this file as the operational checklist for deploying DeepTG.

## Server Access

Run SSH/deploy commands in Anton's local terminal, not inside an agent sandbox.

```bash
ssh tgdeep
```

## Domain

- Production domain: `https://tgdeep.xyz/`
- Production bot domain: `https://bot.tgdeep.xyz/`
- DNS/proxy is managed through Cloudflare.
- Cloudflare should point `tgdeep.xyz` and `bot.tgdeep.xyz` to the server with proxy enabled.
- Cloudflare terminates HTTPS. Traefik only listens on origin HTTP port `80` and routes the domain to the `web` service.
- Cloudflare SSL/TLS mode should be `Flexible` while origin TLS is disabled.

## Deploy Repository

The deploy repository is public:

```bash
git@github.com:deeptgai/deploy.git
```

On the server it must be cloned into `/opt/deploy`:

```bash
cd /opt
git clone git@github.com:deeptgai/deploy.git deploy
```

Only edit deploy files locally, then commit and push. On the server, do not edit files manually; update with `git pull`.

## Project Directory On Server

```bash
cd /opt/deploy
```

## Normal Deploy

1. SSH into the server.
2. Go to the deploy directory.
3. Pull the latest deploy repository changes.
4. Check that `ENV` exists and has the current secrets.
5. Pull/deploy the current image.
6. Apply database schema changes if needed.
7. Check services and logs.

```bash
ssh tgdeep
cd /opt/deploy
git pull
make pull
make deploy
make db-push
make storage-bootstrap
make ps
```

## First Deploy Or Fresh Server

On a fresh server, clone the public deploy repository first:

```bash
ssh tgdeep
cd /opt
git clone git@github.com:deeptgai/deploy.git deploy
cd /opt/deploy
sudo ./scripts/install-ubuntu.sh
nano ENV
make login
make deploy
make db-push
make storage-bootstrap
make ps
```

## Useful Checks

```bash
make ps
make logs-traefik
make logs-web
make logs-bot
make logs-worker
```

## Notes

- `ENV` contains secrets and must not be committed.
- `ADMIN_USERNAME` and `ADMIN_PASSWORD` protect the admin UI with Basic Auth.
- Public snapshot routes stay open: `/s/...` and `/share/snapshots/...`.
- `DOMAIN` controls the Traefik host rule; production value is `tgdeep.xyz`.
- `BOT_DOMAIN` controls the bot webhook host rule; production value is `bot.tgdeep.xyz`.
- `TELEGRAM_WEBHOOK_URL` must be the public HTTPS base URL. Use `https://tgdeep.xyz` so Telegram posts to `/telegram/webhook`; Traefik also keeps `bot.tgdeep.xyz` routed to the bot service.
- Traefik router/service names, HTTP entrypoint, port and network are configured only through `ENV`.
- Existing servers must update `/opt/deploy/ENV` from `ENV.example` after Traefik changes.
- Existing servers must update `/opt/deploy/ENV` from `ENV.example` after SeaweedFS/object storage changes, then run `make storage-bootstrap`.
- `APP_PORT` is no longer used for public traffic; Traefik publishes `TRAEFIK_HTTP_PUBLISHED_PORT`.
- `make login` requires a GitHub token with `read:packages`.
- Traefik publishes port `80`; the web service is not exposed directly.
- Use immutable Docker image tags such as `ghcr.io/deeptgai/workspace:sha-16d79f5`; do not deploy `latest` in production.
