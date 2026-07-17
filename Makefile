VERSION ?= 0.43.0
ARCH ?= arm64

.PHONY: backfill build package repository test lint publish

build: package

package:
	scripts/build-in-container "$(VERSION)" "$(ARCH)"

backfill:
	scripts/backfill-jj $(VERSIONS)

repository:
	scripts/build-repository build/packages build/repository

test:
	scripts/test-in-container "$(ARCH)" "$(VERSION)-0jj1"

lint:
	shellcheck -x -P scripts scripts/*
	markdownlint-cli2 README.md docs/*.md
	actionlint

publish:
	scripts/publish-r2 build/repository
