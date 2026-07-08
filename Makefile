ENV_FILE ?= ENV

ifneq ("$(wildcard $(ENV_FILE))","")
include $(ENV_FILE)
export
endif

STACK ?= deeptg
IMAGE ?= ghcr.io/deeptgai/workspace
IMAGE_TAG ?= latest
TRAEFIK_IMAGE ?= traefik:v3.7

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
