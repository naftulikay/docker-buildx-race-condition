#!/usr/bin/env make -f

SHELL:=$(shell which bash)

DOCKER_IMAGE ?= naftulikay/docker-buildx-race-condition
DOCKER_TAG ?= latest
PROGRESS_FORMAT ?= plain

.PHONY: clean version demo workaround

clean:
	docker buildx prune -f

version:
	docker --version
	docker buildx version

demo: version
	docker buildx build --progress $(PROGRESS_FORMAT) --load -t $(DOCKER_IMAGE):$(DOCKER_TAG) \
		-f Dockerfile ./

workaround: version
	docker buildx build --progress $(PROGRESS_FORMAT) --load -t $(DOCKER_IMAGE):$(DOCKER_TAG) \
		-f Dockerfile.workaround ./