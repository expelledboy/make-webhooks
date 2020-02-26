REGISTRY = docker.io
USERNAME = expelledboy
NAME = $(shell basename $(CURDIR))
IMAGE = $(REGISTRY)/$(USERNAME)/$(NAME)

.EXPORT_ALL_VARIABLES:
.DEFAULT: help

## ==
.PHONY: help build lint unit test clean

help: ## Print help messages
	@sed -n 's/^\([a-zA-Z_-]*\):.*## \(.*\)$$/\1 -- \2/p' Makefile

build: ## Build docker image
	docker build -t $(IMAGE) .

test: ## Run simple unit test
	docker run -d --rm \
		--name $(NAME) \
		-v $(PWD):/webhooks/ \
		-p 3000:3000 \
		$(IMAGE)
	sleep 5
	-curl http://localhost:3000/help
	docker stop $(NAME)

# ==
.PHONY: dev

dev:
	npm run dev

# ==
.PHONY: on-tag bump publish

on-tag:
	@git describe --exact-match --tags $$(git log -n1 --pretty='%h')

bump: IMPACT = patch
bump:
	npm version $(IMPACT)

publish: VERSION = $(shell git describe --always | tr -d v)
publish: MINOR = $(shell echo $(VERSION) | sed -n 's/^\(.\..\).*/\1/p')
publish: on-tag build ## Push docker image to $(REGISTRY)
	docker tag $(IMAGE):latest $(IMAGE):$(VERSION)
	docker tag $(IMAGE):latest $(IMAGE):$(MINOR)
	docker push $(IMAGE):$(VERSION)
	docker push $(IMAGE):$(MINOR)
	docker rmi $(IMAGE):$(VERSION)
	docker rmi $(IMAGE):$(MINOR)
	docker push $(IMAGE):latest

# ==
.PHONY: web intro start-webhooks hello-world crash run-webhook

intro:
	@cat ./docs/welcome.md

web: ## Run webhooks interactively in docker.
	docker run -it --rm \
		--name $(NAME) \
		--volume $(PWD):/webhooks \
		--publish 80:3000 \
		expelledboy/make-webhooks

start-webhooks: env-HOSTNAME ## Deploy as service into docker swarm with traefik.
	docker service create \
		--name make-webhooks \
		--mode global \
		--network web \
		--mount src="$(PWD)",target=/webhooks,type=bind \
		--mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
		--label traefik.enable=true \
		--label traefik.docker.network=web \
		--label traefik.port=3000 \
		--label traefik.frontend.rule=Host:$(HOSTNAME) \
		$(IMAGE)

hello-world: GREET ?= "World"
hello-world: ## Example target using environment variables.
	@echo "Hello, $(GREET)!"

crash: ## Target that always fails.
	exit 10

run-webhook: HOOK = hello-world
run-webhook: ## Run webhook from Makefile and fail on error
	curl -fs http://localhost/$(HOOK)
