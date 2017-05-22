# constants
PROJECT = teleport
CURRENT_DIR = $(shell pwd | sed -e "s/\/cygdrive//g")

.PHONY: build
ifeq (build,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif
build: ## Build containers : ## make build, make build app
	docker-compose -f docker-compose.yml -p $(PROJECT) build $(RUN_ARGS)

.PHONY: logs
ifeq (logs,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif
logs: ## Display container's log : ## make logs, make logs app
	docker-compose -f docker-compose.yml -p $(PROJECT) logs $(RUN_ARGS)

.PHONY: run
ifeq (run,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif
run: ## Run a one-off command : ## make run app echo hello
	docker-compose -f docker-compose.yml -p $(PROJECT) run -d $(RUN_ARGS)

.PHONY: up
ifeq (up,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif
up: ## Create and start containers : ## make up, make up mysql
	docker-compose -f docker-compose.yml -p $(PROJECT) up -d $(RUN_ARGS)

.PHONY: kill
ifeq (kill,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif
kill: ## kill containers : ## make kill, make kill mysql
	docker-compose -f docker-compose.yml -p $(PROJECT) kill $(RUN_ARGS)

.PHONY: rm
ifeq (rm,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif
rm: ## Stop & Remove containers : ## make rm, make rm mysql
	docker-compose -f docker-compose.yml -p $(PROJECT) kill $(RUN_ARGS) && \
	docker-compose -f docker-compose.yml -p $(PROJECT) rm -f $(RUN_ARGS)

ps: ## List containers : ## make ps
	docker-compose -f docker-compose.yml -p $(PROJECT) ps

.PHONY: restart
ifeq (restart,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif
restart: ## Restart services : ## make restart, make restart app
	docker-compose -f docker-compose.yml -p $(PROJECT) kill $(RUN_ARGS) && \
	docker-compose -f docker-compose.yml -p $(PROJECT) rm -f $(RUN_ARGS) && \
	docker-compose -f docker-compose.yml -p $(PROJECT) up -d $(RUN_ARGS)

.PHONY: recreate
ifeq (recreate,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif
recreate: ## Recreate services  : ## make recreate
	docker-compose -f docker-compose.yml -p $(PROJECT) kill $(RUN_ARGS) && \
	docker-compose -f docker-compose.yml -p $(PROJECT) rm -f $(RUN_ARGS) && \
	docker-compose -f docker-compose.yml -p $(PROJECT) build $(RUN_ARGS) && \
	docker-compose -f docker-compose.yml -p $(PROJECT) up -d $(RUN_ARGS)

.PHONY: help
help: ## Show this help message : ## make help
	@echo -e "\nUsage: make [command] [args]\n"
	@grep -P '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ": ## "}; {printf "\t\033[36m%-20s\033[0m \033[33m%-30s\033[0m (e.g. \033[32m%s\033[0m)\n", $$1, $$2, $$3}'
	@echo -e "\n"

.DEFAULT_GOAL := help
