.PHONY: build check check-links lint validate version

build:
	./scripts/build-epub.sh

lint:
	./scripts/lint-markdown.sh

version:
	./scripts/check-version.sh

check-links:
	./scripts/check-links.sh

validate:
	./scripts/validate-epub.sh

check: build
