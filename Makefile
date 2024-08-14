#
#  Author: Hari Sekhon
#  Date: 2024-08-14 22:41:13 +0200 (Wed, 14 Aug 2024)
#
#  vim:ts=4:sts=4:sw=4:noet
#
#  https///github.com/HariSekhon/harisekhon
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# For serious Makefiles see the DevOps Bash tools repo:
#
#	https://github.com/HariSekhon/DevOps-Bash-tools
#
#	Makefile
#	Makefile.in - generic include file with lots of Make targets


# only works in GNU make - is ignored by Mac's built-in make - not portable, should avoid and call bash scripts instead
#.ONESHELL:

# parallelize
#MAKEFLAGS = -j2

SHELL = /usr/bin/env bash

.SHELLFLAGS += -eu -o pipefail

#PATH := $(PATH):$(PWD)/bash-tools

.PHONY: *

default:  ## run default (build -> tests)
	@echo "running default build:"
	$(MAKE) build

build: #init  ## run build (only tests at this time)
	@echo "running build:"
	$(MAKE) pre-commit

pre-commit:  ## run pre-commit on all files
	pre-commit run --all-files

precommit: pre-commit  ## run pre-commit
	@:

test: pre-commit  ## run tests (pre-commit)
	@:

#.PHONY: init
#init:
#    @echo "running init:"
#    if type -P git; then git submodule update --init --recursive; fi
#    @echo
#
#.PHONY: bash-tools
#bash-tools:
#    @if ! command -v check_pytools.sh; then \
#        curl -L https://git.io/bash-bootstrap | sh; \
#    fi
#
#.PHONY: test
#test: bash-tools
#    @echo "running tests:"
#    check_pytools.sh

push: test  ## push to origin (usually GitHub)
	git push

wc:
	 find . -maxdepth 1 -type f | xargs wc -l

# Prints the ## suffixed comment from each target to dynamically create a help listing, with colour
help: ## Show this help
	@egrep '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
