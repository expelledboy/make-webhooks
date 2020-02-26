REGISTRY_HOST = docker.io
USERNAME = expelledboy
NAME = $(shell basename $(CURDIR))
IMAGE = $(REGISTRY_HOST)/$(USERNAME)/$(NAME)

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
		-v $(PWD):/webhook/ \
		-p 3000:3000 \
		$(IMAGE)
	sleep 5
	-curl http://localhost:3000/help
	docker stop $(NAME)

# ==
.PHONY: on-tag bump publish

on-tag:
	@git describe --exact-match --tags $$(git log -n1 --pretty='%h')

bump-package: IMPACT = patch
bump-package:
	npm version $(IMPACT)

bump: VERSION = $(shell node -p "require('./package.json').version")
bump: bump-package ## Bump release version eg. `make IMPACT=patch bump`
	git add package.json
	git commit -m 'Release version $(VERSION)'
	git tag $(VERSION)

publish: VERSION = $(shell git describe --always)
publish: on-tag build ## Push docker image to $(REGISTRY_HOST)
	echo docker push $(IMAGE):$(VERSION)
	echo docker push $(IMAGE):latest

# ==
