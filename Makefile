GIT_REVISION := $(shell git rev-parse --short HEAD)

.PHONY: cuefmt
cuefmt:
	@(find . -name '*.cue' -exec cue fmt -s {} \;)

.PHONY: cuelint
cuelint: cuefmt
	@test -z "$$(git status -s . | grep -e "^ M"  | grep .cue | cut -d ' ' -f3 | tee /dev/stderr)"
	@echo "Cue files are well formatted!"

.PHONY: shellcheck
shellcheck:
	@shellcheck ./stdlib/*.bats ./stdlib/*.bash
	@echo "Bats files are well formatted!"

.PHONY: lint
lint: shellcheck cuelint

.PHONY: universe-test
universe-test:
	yarn --cwd "./universe" install

	# Set dagger path if no one exist
	@if [ -z "$DAGGER_BINARY" ]; then DAGGER_BINARY="/usr/local/bin/dagger"; fi
	yarn --cwd "./universe" test

