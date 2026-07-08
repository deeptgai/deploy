ENV_FILE ?= ENV

ifneq ("$(wildcard $(ENV_FILE))","")
include $(ENV_FILE)
export
endif

STACK ?= deeptg
IMAGE ?= ghcr.io/deeptgai/workspace
IMAGE_TAG ?= latest
TRAEFIK_IMAGE ?= traefik:v3.7
TRAEFIK_NETWORK ?= $(STACK)_app
TRAEFIK_ROUTER_NAME ?= deeptg
TRAEFIK_SERVICE_NAME ?= deeptg
TRAEFIK_WEB_ENTRYPOINT ?= web
TRAEFIK_WEBSECURE_ENTRYPOINT ?= websecure
TRAEFIK_HTTP_PORT ?= 80
TRAEFIK_HTTPS_PORT ?= 443
TRAEFIK_HTTP_PUBLISHED_PORT ?= 80
TRAEFIK_HTTPS_PUBLISHED_PORT ?= 443
TRAEFIK_SWARM_ENDPOINT ?= unix:///var/run/docker.sock
TRAEFIK_DOCKER_SOCKET ?= /var/run/docker.sock
TRAEFIK_CERT_RESOLVER ?= le
TRAEFIK_ACME_STORAGE ?= /letsencrypt/acme.json
TRAEFIK_ACME_VOLUME ?= $(STACK)_traefik_letsencrypt
TRAEFIK_LOG_LEVEL ?= INFO
TRAEFIK_ACCESSLOG ?= true
WEB_INTERNAL_PORT ?= 3000
POSTGRES_VOLUME ?= $(STACK)_postgres_data
REDIS_VOLUME ?= $(STACK)_redis_data

.PHONY: help check-env login pull deploy db-push ps logs logs-traefik logs-web logs-worker rm init-swarm

help:
	@printf "Targets:\\n"
	@printf "  make init-swarm   Initialize Docker Swarm if needed\\n"
	@printf "  make login        Login to ghcr.io\\n"
	@printf "  make pull         Pull application image\\n"
	@printf "  make deploy       Deploy/update Docker Swarm stack\\n"
	@printf "  make db-push      Apply Prisma schema\\n"
	@printf "  make ps           Show stack services\\n"
	@printf "  make logs-traefik Follow Traefik logs\\n"
	@printf "  make logs-web     Follow web logs\\n"
	@printf "  make logs-worker  Follow worker logs\\n"
	@printf "  make rm           Remove stack\\n"

check-env:
	@test -f "$(ENV_FILE)" || (echo "Missing $(ENV_FILE). Copy ENV.example to $(ENV_FILE)." && exit 1)

init-swarm:
	@docker info --format '{{.Swarm.LocalNodeState}}' | grep -q active || docker swarm init

login:
	@echo "Login to GitHub Container Registry. Use a GitHub token with read:packages."
	docker login ghcr.io

pull: check-env
	docker pull $(IMAGE):$(IMAGE_TAG)
	docker pull $(TRAEFIK_IMAGE)

deploy: check-env init-swarm
	docker stack deploy --with-registry-auth --detach=false -c stack.yml $(STACK)

db-push: check-env
	docker run --rm --network $(STACK)_app --env-file $(ENV_FILE) $(IMAGE):$(IMAGE_TAG) npm run db:push

ps:
	docker stack services $(STACK)

logs:
	docker service logs -f $(STACK)_web

logs-traefik:
	docker service logs -f $(STACK)_traefik

logs-web:
	docker service logs -f $(STACK)_web

logs-worker:
	docker service logs -f $(STACK)_worker

rm:
	docker stack rm $(STACK)
