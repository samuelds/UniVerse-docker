# Set user and group id
ifeq ($(OS),Windows_NT)
	HOST_UID := "1000"
	HOST_GID := "1000"
else
	HOST_UID := $(shell id -u)
	HOST_GID := $(shell id -g)
endif

# Executables (local)
DOCKER_COMP := HOST_UID=$(HOST_UID) HOST_GID=$(HOST_GID) docker compose -p "universe"

# Docker containers
PHP_CONT = $(DOCKER_COMP) exec php
SYMFONY_CONT = $(DOCKER_COMP) exec php
COMPOSER_CONT = $(DOCKER_COMP) run --rm composer
NODE_CONT = $(DOCKER_COMP) run --rm node

# Executables
PHP      = $(PHP_CONT) php
SYMFONY  = $(SYMFONY_CONT) php bin/console
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
	
ifeq ($(OS),Windows_NT)
    SSL_CMD := powershell -Command "openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ./files/nginx/ssl/localhost.key -out ./files/nginx/ssl/localhost.crt -subj \"/C=FR/ST=Paris/L=Paris/O=42/OU=42/CN=localhost\""
else
    SSL_CMD := openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ./files/nginx/ssl/localhost.key -out ./files/nginx/ssl/localhost.crt -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=42/CN=localhost"
endif

## Nginx
ssl: ## Generate https certificate for domaine
	@$(SSL_CMD)
	@echo "[ok] SSL certificate generated"
	@$(DOCKER_COMP) restart web
	@echo "[ok] Web server listening on : http://localhost and https://localhost"

## —— 🎵 🐳 The Symfony Docker Makefile 🐳 🎵 ——————————————————————————————————
help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9\./_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

## —— Docker 🐳 ————————————————————————————————————————————————————————————————
build: ## Builds the Docker images
	@echo "[info] current user: $(HOST_UID):$(HOST_UID)"
	@$(DOCKER_COMP) build --pull --no-cache

up: ## Start the docker hub in detached mode (no logs)
	@echo "[info] current user: $(HOST_UID):$(HOST_UID)"
	@$(DOCKER_COMP) up --detach
	@echo "[ok] Web server listening on : http://app.dev.localhost and https://app.dev.localhost"

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

cc: ## Clear the cache
	@$(SYMFONY) cache:clear

entity: ## Create a new entity
	@$(SYMFONY) make:entity

controller: ## Create a new controller
	@$(SYMFONY) make:controller

migration: ## Create a new migration
	@$(SYMFONY) make:migration

migrate: ## Migrate the database
	@$(SYMFONY) doctrine:migrations:migrate --no-interaction

fixtures: ## Load fixtures
	@$(SYMFONY) doctrine:fixtures:load --no-interaction