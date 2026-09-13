# --- Variables --------------------------------------------------------
.DEFAULT_GOAL := all

COMPOSE_FILE := srcs/docker-compose.yml
COMPOSE := docker compose -f $(COMPOSE_FILE)

# --- Inception environment variables ----------------------------------

-include srcs/.env

DEFAULT_DATA_ROOT_PATH := /home/vpoka/data
DEFAULT_DATA_DRIVE_DIR := database
DEFAULT_WEB_DRIVE_DIR := website

DATA_ROOT_PATH ?= $(DEFAULT_DATA_ROOT_PATH)
DATA_DRIVE_DIR ?= $(DEFAULT_DATA_DRIVE_DIR)
WEB_DRIVE_DIR ?= $(DEFAULT_WEB_DRIVE_DIR)

export DATA_ROOT_PATH DATA_DRIVE_DIR WEB_DRIVE_DIR

# --- Template files ---------------------------------------------------

SECRETS_DIR := srcs/secrets
SECRETS :=	mariadb_root_password \
			mariadb_user_password \
			wordpress_admin_password \
			wordpress_user_password

define INCEPTION_ENV_TEMPLATE
# --- Domain (required) ---
# WORDPRESS_DOMAIN=vpoka.42.fr
# ADMINER_SUBDOMAIN=adminer

# --- Database ---
# WORDPRESS_DB_NAME=wordpress
# WORDPRESS_DB_USER=wordpress
# WORDPRESS_DB_TABLE_PREFIX=wordpress_
# DB_CHARSET=utf8mb4
# DB_COLLATE=utf8mb4_uca1400_ai_ci

# --- WordPress ---
# WORDPRESS_VERSION=7.0.4
# WORDPRESS_TITLE=Inception
# WORDPRESS_ADMIN_NAME=owner
# WORDPRESS_ADMIN_EMAIL=admin@invalid.email
# WORDPRESS_USER_NAME=author
# WORDPRESS_USER_EMAIL=author@invalid.email

# --- Ports ---
# NGINX_PORT=443
# MARIADB_PORT=3306
# WORDPRESS_FPM_PORT=9000
# ADMINER_PORT=8080

# --- Volumes ---
# DATA_ROOT_PATH=/home/vpoka/data
# DATA_DRIVE_DIR=database
# WEB_DRIVE_DIR=website
endef
export INCEPTION_ENV_TEMPLATE

# --- Logging helpers --------------------------------------------------
C_RESET  := \x1b[0m
C_CYAN   := \x1b[36m
C_YELLOW := \x1b[33m
C_BOLD   := \x1b[1m

define log_target
	@printf "$(C_BOLD)$(C_CYAN)==>$(C_RESET) $(C_BOLD)%s$(C_RESET)\n" "$@"
endef

STEP_PREFIX := \t$(C_CYAN)->$(C_RESET)

# --- Default rules ----------------------------------------------------
.PHONY: all check env-check secrets-check dirs-check domain-check clean fclean re up attached down start stop restart build pause unpause ps logs exec run templates env-template dirs secrets-template rm-dirs rm-env rm-secrets help

all: check
	$(log_target)
	@printf "$(STEP_PREFIX) Building and starting containers in detached mode\n"
	@$(COMPOSE) up --build -d

clean:
	$(log_target)
	@printf "$(STEP_PREFIX) Stopping and removing containers, networks, volumes and images\n"
	@$(COMPOSE) down --volumes --rmi all --remove-orphans

fclean: clean rm-env rm-secrets rm-dirs

re: clean all

# --- Docker compose rules ---------------------------------------------

up:
	$(log_target)
	@printf "$(STEP_PREFIX) Starting containers in detached mode\n"
	@$(COMPOSE) up -d

attached:
	$(log_target)
	@printf "$(STEP_PREFIX) Starting containers in attached mode\n"
	@$(COMPOSE) up

build:
	$(log_target)
	@printf "$(STEP_PREFIX) Building service images\n"
	@$(COMPOSE) build

start:
	$(log_target)
	@printf "$(STEP_PREFIX) Starting $(if $(S),container '$(S)',all existing containers)\n"
	@$(COMPOSE) start $(S)

stop:
	$(log_target)
	@printf "$(STEP_PREFIX) Stopping $(if $(S),container '$(S)',all running containers)\n"
	@$(COMPOSE) stop $(S)

restart:
	$(log_target)
	@printf "$(STEP_PREFIX) Restarting $(if $(S),container '$(S)',all containers)\n"
	@$(COMPOSE) restart $(S)

down:
	$(log_target)
	@printf "$(STEP_PREFIX) Stopping and removing containers\n"
	@$(COMPOSE) down

pause:
	$(log_target)
	@printf "$(STEP_PREFIX) Pausing $(if $(S),service '$(S)',all services)\n"
	@$(COMPOSE) pause $(S)

unpause:
	$(log_target)
	@printf "$(STEP_PREFIX) Resuming $(if $(S),service '$(S)',all services)\n"
	@$(COMPOSE) unpause $(S)

ps:
	$(log_target)
	@$(COMPOSE) ps -a $(S)

logs:
	$(log_target)
	@$(COMPOSE) logs $(S)

exec:
	$(log_target)
	@if [ -z "$(S)" ]; then \
		printf "$(C_YELLOW)[ERROR] Usage: make exec S=<service> [C=\"command\"]$(C_RESET)\n"; \
		exit 1; \
	fi
	@$(COMPOSE) exec $(S) $(if $(C),$(C),ash)

run:
	$(log_target)
	@if [ -z "$(S)" ]; then \
		printf "$(C_YELLOW)[ERROR] Usage: make run S=<service> [C=\"command\"]$(C_RESET)\n"; \
		exit 1; \
	fi
	@$(COMPOSE) run --rm $(S) $(C)

# --- Extra rules ------------------------------------------------------

check: env-check secrets-check dirs-check domain-check
	$(log_target)

env-check:
	$(log_target)
	@if [ ! -f srcs/.env ]; then \
		printf "$(C_YELLOW)[ERROR] missing 'srcs/.env' (run: make env-template)$(C_RESET)\n"; \
		exit 1; \
	fi
	@printf "$(STEP_PREFIX) domain         : $(WORDPRESS_DOMAIN)\n"
	@printf "$(STEP_PREFIX) public port    : $(or $(NGINX_PORT),443)\n"
	@printf "$(STEP_PREFIX) admin username : $(or $(WORDPRESS_ADMIN_NAME),owner)\n"

secrets-check:
	$(log_target)
	@missing=0; \
	for secret in $(SECRETS); do \
		if [ ! -f "$(SECRETS_DIR)/$$secret.txt" ]; then \
			printf "$(C_YELLOW)[ERROR] missing '$(SECRETS_DIR)/$$secret.txt' (run: make secrets-template)$(C_RESET)\n"; \
			missing=1; \
		fi; \
	done; \
	if [ "$$missing" -ne 0 ]; then \
		exit 1; \
	fi
	@printf "$(STEP_PREFIX) found\n"

dirs-check:
	$(log_target)
	@missing=0; \
	if [ ! -d "$(DATA_ROOT_PATH)/$(DATA_DRIVE_DIR)" ]; then \
		printf "$(C_YELLOW)[ERROR] missing directory '$(DATA_ROOT_PATH)/$(DATA_DRIVE_DIR)' (run: make dirs)$(C_RESET)\n"; \
		missing=1; \
	fi; \
	if [ ! -d "$(DATA_ROOT_PATH)/$(WEB_DRIVE_DIR)" ]; then \
		printf "$(C_YELLOW)[ERROR] missing directory '$(DATA_ROOT_PATH)/$(WEB_DRIVE_DIR)' (run: make dirs)$(C_RESET)\n"; \
		missing=1; \
	fi; \
	if [ "$$missing" -ne 0 ]; then \
		exit 1; \
	fi
	@printf "$(STEP_PREFIX) found '$(DATA_ROOT_PATH)/*'\n"

domain-check:
	$(log_target)
	@if [ -z "$(WORDPRESS_DOMAIN)" ]; then \
		printf "$(C_YELLOW)[ERROR] WORDPRESS_DOMAIN is not set (uncomment it in srcs/.env)$(C_RESET)\n"; \
		exit 1; \
	fi
	@printf "$(STEP_PREFIX) found\n"

templates: env-template secrets-template
	$(log_target)
	@printf '$(C_YELLOW)[WARNING] Before starting the services, please fill out:\n\t1. srcs/.env\n\t2. srcs/secrets/*.txt\n$(C_RESET)'

env-template:
	$(log_target)
	@printf "$(STEP_PREFIX) Checking 'srcs/.env'\n"
	@if [ ! -f srcs/.env ]; then \
		echo -n "$$INCEPTION_ENV_TEMPLATE" > srcs/.env; \
		printf "$(STEP_PREFIX) created 'srcs/.env' from template\n"; \
	else \
		printf "$(STEP_PREFIX) 'srcs/.env' already exists\n"; \
	fi

dirs:
	$(log_target)
	@printf "$(STEP_PREFIX) Checking host data directories\n"
	@if [ ! -d "$(DATA_ROOT_PATH)/$(DATA_DRIVE_DIR)" ]; then \
		mkdir -p "$(DATA_ROOT_PATH)/$(DATA_DRIVE_DIR)"; \
		printf "$(STEP_PREFIX) created '$(DATA_ROOT_PATH)/$(DATA_DRIVE_DIR)'\n"; \
	else \
		printf "$(STEP_PREFIX) '$(DATA_ROOT_PATH)/$(DATA_DRIVE_DIR)' already exists\n"; \
	fi
	@if [ ! -d "$(DATA_ROOT_PATH)/$(WEB_DRIVE_DIR)" ]; then \
		mkdir -p "$(DATA_ROOT_PATH)/$(WEB_DRIVE_DIR)"; \
		printf "$(STEP_PREFIX) created '$(DATA_ROOT_PATH)/$(WEB_DRIVE_DIR)'\n"; \
	else \
		printf "$(STEP_PREFIX) '$(DATA_ROOT_PATH)/$(WEB_DRIVE_DIR)' already exists\n"; \
	fi

secrets-template:
	$(log_target)
	@printf "$(STEP_PREFIX) Creating secret files in $(SECRETS_DIR)\n"
	@for secret in $(SECRETS); do \
		if [ ! -f "$(SECRETS_DIR)/$$secret.txt" ]; then \
			touch "$(SECRETS_DIR)/$$secret.txt"; \
			printf "$(STEP_PREFIX) created '$(SECRETS_DIR)/$$secret.txt' (empty)\n"; \
		else \
			printf "$(STEP_PREFIX) '$(SECRETS_DIR)/$$secret.txt' already exists\n"; \
		fi; \
	done

rm-dirs:
	$(log_target)
	@printf "$(STEP_PREFIX) Removing host data directory '$(DATA_ROOT_PATH)' (incl. '$(DATA_DRIVE_DIR)' and '$(WEB_DRIVE_DIR)')\n"
	@sudo rm -rf $(DATA_ROOT_PATH)

rm-env:
	$(log_target)
	@printf "$(STEP_PREFIX) Removing 'srcs/.env'\n"
	@rm -f srcs/.env

rm-secrets:
	$(log_target)
	@printf "$(STEP_PREFIX) Removing secret files\n"
	@rm -f $(SECRETS_DIR)/*.txt

help:
	@printf "$(C_BOLD)Available targets:$(C_RESET) %s\n"
	@printf "$(C_BOLD)- Standard commands$(C_RESET) %s\n"
	@printf "  - all           : (default) Check setup, then build and start containers in detached mode\n"
	@printf "  - clean         : Remove all docker resources: containers, networks, volumes, images\n"
	@printf "  - fclean        : clean + remove .env, secrets and host data (!all persistent data lost!)\n"
	@printf "  - re            : Full rebuild: clean then all (keeps config and data)\n"
	@printf "$(C_BOLD)- Docker compose commands$(C_RESET) %s\n"
	@printf "  - up            : Start containers in detached mode (no build)\n"
	@printf "  - attached      : Start containers in attached mode (no build)\n"
	@printf "  - down          : Stop and remove containers\n"
	@printf "  - start         : Start existing containers [S]\n"
	@printf "  - stop          : Stop running containers [S]\n"
	@printf "  - restart       : Restart containers [S]\n"
	@printf "  - pause         : Pause all services [S]\n"
	@printf "  - unpause       : Resume paused services [S]\n"
	@printf "  - build         : Build or rebuild services\n"
	@printf "  - ps            : List running containers [S]\n"
	@printf "  - logs          : View output of containers [S]\n"
	@printf "  - exec          : Run a command in a running service [S, C]\n"
	@printf "  - run           : Run a one-off command in a new container [S, C]\n"
	@printf "$(C_BOLD)- Optional variables$(C_RESET) %s\n"
	@printf "  - S=<service>   : Limit the command to one service\n"
	@printf "                      - Used by: exec, run, start, stop, restart, pause, unpause, ps, logs\n"
	@printf "                      - Possible values: nginx, wordpress, mariadb\n"
	@printf "  - C=\"<command>\" : Command to run (exec/run only).\n"
	@printf "                      - Examples: C=\"ls -la\"  C=\"mysql -u root -p\"\n"
	@printf "$(C_BOLD)- Extra commands$(C_RESET) %s\n"
	@printf "  - check            : Run all check steps below (also run by all)\n"
	@printf "  - env-check        : Verify srcs/.env exists; print domain, port, and admin name\n"
	@printf "  - secrets-check    : Verify secret files exist\n"
	@printf "  - dirs-check       : Verify host data directories exist\n"
	@printf "  - domain-check     : Verify WORDPRESS_DOMAIN is set; print it\n"
	@printf "  - templates        : Run env and secrets template steps below\n"
	@printf "  - env-template     : Generate srcs/.env from template (skips if exists)\n"
	@printf "  - secrets-template : Generate missing secret placeholder files\n"
	@printf "  - dirs             : Create host data directories if missing\n"
	@printf "  -----\n"
	@printf "  - rm-dirs       : Remove the host data directory (all persistent data)\n"
	@printf "  - rm-env        : Remove srcs/.env\n"
	@printf "  - rm-secrets    : Remove secret files\n"
	@printf "  -----\n"
	@printf "  - help          : Display this help message\n"
