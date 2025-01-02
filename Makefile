SHELL := /usr/bin/bash

.PHONY: fmt
fmt:
	stylua -g '*.lua' -- .

.PHONY: lint
lint:
	typos -w

.PHONY: check
check: lint fmt

.PHONY: setup
setup:
	@if [ ! -d "$${HOME}/.cache/$${NVIM_APPNAME:-nvim}/local-devcontainer.nvim/templates/" ]; then \
		echo "Cloning repository..."; \
		mkdir -p "$${HOME}/.cache/$${NVIM_APPNAME:-nvim}/local-devcontainer.nvim"; \
		git clone https://github.com/devcontainers/templates.git "$${HOME}/.cache/$${NVIM_APPNAME:-nvim}/local-devcontainer.nvim/templates"; \
	else \
		echo "Pulling latest changes..."; \
		git -C "$${HOME}/.cache/$${NVIM_APPNAME:-nvim}/local-devcontainer.nvim/templates" pull; \
	fi
