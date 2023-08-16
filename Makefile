# if vars not set specifially: try default to environment, else fixed value.
# strip to ensure spaces are removed in future editorial mistakes.
# tested to work consistently on popular Linux flavors and Mac.
ifeq ($(user),)
	# USER retrieved from env, UID from shell.
	HOST_USER ?= $(strip $(if $(USER),$(USER),nodummy))
	HOST_UID ?= $(strip $(if $(shell id -u),$(shell id -u),4000))
else
	# allow override by adding user= and/ or uid=  (lowercase!).
	# uid= defaults to 0 if user= set (i.e. root).
	HOST_USER = $(user)
	HOST_UID = $(strip $(if $(uid),$(uid),0))
endif

# export such that its passed to shell functions for Docker to pick up.
export HOST_USER
export HOST_UID

# Executables (local)
DOCKER_COMP := docker compose

# Docker containers
SYMFONY_CONT = $(DOCKER_COMP) exec php
COMPOSER_CONT = $(DOCKER_COMP) run --rm composer
NODE_CONT = $(DOCKER_COMP) run --rm node
PHP_CONT = $(DOCKER_COMP) exec php

# Executables
PHP      = $(PHP_CONT) php
SYMFONY  = $(SYMFONY_CONT) bin/console
COMPOSER = $(COMPOSER_CONT) composer
YARN     = $(NODE_CONT) yarn
NPM		 = $(NODE_CONT) npm

# Misc
.DEFAULT_GOAL = help
.PHONY        : help build up start down logs sh composer vendor sf cc

## App
install: ## Copy files
install: ssl
	@cp .env.dist .env
	@echo "[ok] Env file"

## Nginx
ssl: ## Generate https certificate for domaine
	@openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ./files/nginx/ssl/localhost.key -out ./files/nginx/ssl/localhost.crt -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=42/CN=localhost"
	@echo "[ok] SSL certificate generated"
	@$(DOCKER_COMP) restart web
	@echo "[ok] Web server listening on : http://localhost and https://localhost"

## —— 🎵 🐳 The Symfony Docker Makefile 🐳 🎵 ——————————————————————————————————
help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9\./_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

## —— Docker 🐳 ————————————————————————————————————————————————————————————————
build: ## Builds the Docker images
	@$(DOCKER_COMP) build --pull --no-cache

up: ## Start the docker hub in detached mode (no logs)
	@$(DOCKER_COMP) -p "universe" up --detach
	@echo "[info] current user: $(HOST_USER)(uid=$(HOST_UID))"
	@echo "[ok] Web server listening on : http://localhost and https://localhost"

start: build up ## Build and start the containers

down: ## Stop the docker hub
	@$(DOCKER_COMP) down --remove-orphans

logs: ## Show live logs
	@$(DOCKER_COMP) logs --tail=0 --follow

sh: ## Connect to the PHP FPM container
	@$(PHP_CONT) sh

## —— Composer 🧙 ——————————————————————————————————————————————————————————————
composer: ## Run composer, pass the parameter "c=" to run a given command, example: make composer c='req symfony/orm-pack'
	@$(eval c ?=)
	@$(COMPOSER) $(c)

vendor: ## Install vendors according to the current composer.lock file
vendor: c=install --prefer-dist --no-progress --no-scripts --no-interaction
vendor: composer

## —— Node 🧙 ——————————————————————————————————————————————————————————————————
yarn: ## Run yarn, pass the parameter "c=" to run a given command, example: make yarn c='install'
	@$(eval c ?=)
	@$(YARN) $(c)

encore: ## Run encore, pass the parameter "c=" to run a given command, example: make encore c='dev'
	@$(eval c ?=)
	@$(YARN) encore $(c)

npm: ## Run npm, pass the parameter "c=" to run a given command, example: make npm c='install'
	@$(eval c ?=)
	@$(NPM) $(c)

## —— Symfony 🎵 ———————————————————————————————————————————————————————————————
db: ## Install the Symfony application
	@$(SYMFONY) doctrine:database:create --if-not-exists
	@$(SYMFONY) doctrine:migrations:migrate --no-interaction
	#@$(SYMFONY) doctrine:fixtures:load --no-interaction

sf: ## List all Symfony commands or pass the parameter "c=" to run a given command, example: make sf c=about
	@$(eval c ?=)
	@$(SYMFONY) $(c)

cc: c=c:c ## Clear the cache
cc: sf

migration: ## Create a new migration
	@$(SYMFONY) make:migration

migrate: ## Migrate the database
	@$(SYMFONY) doctrine:migrations:migrate --no-interaction

fixtures: ## Load fixtures
	@$(SYMFONY) doctrine:fixtures:load --no-interaction