# Deploy Agent Notes

Use this file as the operational checklist for deploying DeepTG.

## Server Access

Run SSH/deploy commands in Anton's local terminal, not inside an agent sandbox.

```bash
ssh tgdeep
```

## Domain

- Production domain: `https://tgdeep.xyz/`
- DNS/proxy is managed through Cloudflare.
- Cloudflare should point `tgdeep.xyz` to the server and proxy traffic to ports `80`/`443`.
- Traefik terminates HTTPS and routes the domain to the `web` service.

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
make ps
```

## Useful Checks

```bash
make ps
make logs-traefik
make logs-web
make logs-worker
```

## Notes

- `ENV` contains secrets and must not be committed.
- `ADMIN_USERNAME` and `ADMIN_PASSWORD` protect the admin UI with Basic Auth.
- Public snapshot routes stay open: `/s/...` and `/share/snapshots/...`.
- `DOMAIN` controls the Traefik host rule; production value is `tgdeep.xyz`.
- Traefik router/service names, entrypoints, ports, network and ACME storage are configured only through `ENV`.
- `TRAEFIK_ACME_EMAIL` is used for Let's Encrypt certificate registration.
- Existing servers must update `/opt/deploy/ENV` from `ENV.example` after Traefik changes.
- `APP_PORT` is no longer used for public traffic; Traefik publishes `TRAEFIK_HTTP_PUBLISHED_PORT` and `TRAEFIK_HTTPS_PUBLISHED_PORT`.
- `make login` requires a GitHub token with `read:packages`.
- Traefik publishes ports `80` and `443`; the web service is not exposed directly.
- The Docker image defaults to `ghcr.io/deeptgai/workspace:latest`.
