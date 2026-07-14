ENV_FILE ?= ENV

ifneq ("$(wildcard $(ENV_FILE))","")
include $(ENV_FILE)
export
endif

STACK ?= deeptg
IMAGE ?= ghcr.io/deeptgai/workspace
IMAGE_TAG ?= sha-13d6630
TRAEFIK_IMAGE ?= traefik:v3.7
SEAWEEDFS_IMAGE ?= chrislusf/seaweedfs:3.85
DOMAIN ?= tgdeep.xyz
BOT_DOMAIN ?= bot.$(DOMAIN)
TRAEFIK_NETWORK ?= $(STACK)_app
TRAEFIK_ROUTER_NAME ?= deeptg
TRAEFIK_SERVICE_NAME ?= deeptg
TRAEFIK_BOT_ROUTER_NAME ?= deeptg-bot
TRAEFIK_BOT_WEBHOOK_ROUTER_NAME ?= deeptg-bot-webhook
TRAEFIK_BOT_SERVICE_NAME ?= deeptg-bot
TRAEFIK_WEB_ENTRYPOINT ?= web
TRAEFIK_HTTP_PORT ?= 80
TRAEFIK_HTTP_PUBLISHED_PORT ?= 80
TRAEFIK_SWARM_ENDPOINT ?= unix:///var/run/docker.sock
TRAEFIK_DOCKER_SOCKET ?= /var/run/docker.sock
TRAEFIK_LOG_LEVEL ?= INFO
TRAEFIK_ACCESSLOG ?= true
WEB_INTERNAL_PORT ?= 3000
BOT_REPLICAS ?= 1
TELEGRAM_WEBHOOK_PORT ?= 8787
POSTGRES_VOLUME ?= $(STACK)_postgres_data
REDIS_VOLUME ?= $(STACK)_redis_data
SEAWEEDFS_VOLUME ?= $(STACK)_seaweedfs_data

.PHONY: help check-env check-image-tag login pull deploy db-migrate storage-bootstrap ps logs logs-traefik logs-web logs-bot logs-worker rm init-swarm

help:
	@printf "Targets:\\n"
	@printf "  make init-swarm   Initialize Docker Swarm if needed\\n"
	@printf "  make login        Login to ghcr.io\\n"
	@printf "  make pull         Pull application image\\n"
	@printf "  make deploy       Deploy/update Docker Swarm stack\\n"
	@printf "  make db-migrate   Apply Prisma migrations\\n"
	@printf "  make storage-bootstrap Create object storage bucket\\n"
	@printf "  make ps           Show stack services\\n"
	@printf "  make logs-traefik Follow Traefik logs\\n"
	@printf "  make logs-web     Follow web logs\\n"
	@printf "  make logs-bot     Follow bot logs\\n"
	@printf "  make logs-worker  Follow worker logs\\n"
	@printf "  make rm           Remove stack\\n"

check-env:
	@test -f "$(ENV_FILE)" || (echo "Missing $(ENV_FILE). Copy ENV.example to $(ENV_FILE)." && exit 1)

check-image-tag: check-env
	@test "$(IMAGE_TAG)" != "latest" || (echo "Refusing to deploy IMAGE_TAG=latest. Use an immutable tag like sha-16d79f5." && exit 1)

init-swarm:
	@docker info --format '{{.Swarm.LocalNodeState}}' | grep -q active || docker swarm init

login:
	@echo "Login to GitHub Container Registry. Use a GitHub token with read:packages."
	docker login ghcr.io

pull: check-image-tag
	docker pull $(IMAGE):$(IMAGE_TAG)
	docker pull $(TRAEFIK_IMAGE)
	docker pull $(SEAWEEDFS_IMAGE)

deploy: check-image-tag init-swarm
	@if docker network inspect $(STACK)_app >/dev/null 2>&1; then $(MAKE) db-migrate; fi
	docker stack deploy --with-registry-auth --detach=false -c stack.yml $(STACK)
	$(MAKE) db-migrate

db-migrate: check-image-tag
	docker run --rm --network $(STACK)_app --env-file $(ENV_FILE) $(IMAGE):$(IMAGE_TAG) npm run db:deploy

storage-bootstrap: check-image-tag
	docker run --rm --network $(STACK)_app --env-file $(ENV_FILE) $(IMAGE):$(IMAGE_TAG) npm run cli -- storage:bootstrap

ps:
	docker stack services $(STACK)

logs:
	docker service logs -f $(STACK)_web

logs-traefik:
	docker service logs -f $(STACK)_traefik

logs-web:
	docker service logs -f $(STACK)_web

logs-bot:
	docker service logs -f $(STACK)_bot

logs-worker:
	docker service logs -f $(STACK)_worker

rm:
	docker stack rm $(STACK)
