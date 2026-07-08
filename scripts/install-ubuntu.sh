#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${APP_DIR:-/opt/deploy}"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_USER="${SUDO_USER:-$USER}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo $0"
  exit 1
fi

echo "Installing system packages..."
apt-get update
apt-get install -y ca-certificates curl gnupg git make rsync

if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

systemctl enable --now docker
usermod -aG docker "${TARGET_USER}" || true

if ! docker info --format '{{.Swarm.LocalNodeState}}' | grep -q active; then
  echo "Initializing Docker Swarm..."
  docker swarm init
fi

echo "Installing deploy files to ${APP_DIR}..."
mkdir -p "${APP_DIR}"
rsync -a --delete \
  --exclude '.git' \
  --exclude 'ENV' \
  "${SOURCE_DIR}/" "${APP_DIR}/"

if [[ ! -f "${APP_DIR}/ENV" ]]; then
  cp "${APP_DIR}/ENV.example" "${APP_DIR}/ENV"
  chmod 600 "${APP_DIR}/ENV"
fi

chown -R "${TARGET_USER}:${TARGET_USER}" "${APP_DIR}"

cat <<EOF

Install complete.

Next steps:
  cd ${APP_DIR}
  nano ENV
  make login
  make deploy
  make db-push

If this user was not already in the docker group, log out and back in before running docker without sudo.
EOF
