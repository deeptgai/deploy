# Deploy Agent Notes

Use this file as the operational checklist for deploying DeepTG.

## Server Access

```bash
ssh tgdeep
```

## Project Directory On Server

```bash
cd /opt/deeptg/deploy
```

## Normal Deploy

1. SSH into the server.
2. Go to the deploy directory.
3. Check that `ENV` exists and has the current secrets.
4. Pull/deploy the current image.
5. Apply database schema changes if needed.
6. Check services and logs.

```bash
ssh tgdeep
cd /opt/deeptg/deploy
make pull
make deploy
make db-push
make ps
```

## First Deploy Or Fresh Server

From a prepared checkout that contains this `deploy` directory:

```bash
sudo ./scripts/install-ubuntu.sh
cd /opt/deeptg/deploy
nano ENV
make login
make deploy
make db-push
make ps
```

## Useful Checks

```bash
make ps
make logs-web
make logs-worker
```

## Notes

- `ENV` contains secrets and must not be committed.
- `make login` requires a GitHub token with `read:packages`.
- The web app listens on `APP_PORT` from `ENV`; default is `3000`.
- The Docker image defaults to `ghcr.io/deeptgai/workspace:latest`.
