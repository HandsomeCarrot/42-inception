# --- Variables ---------------------------------------------------------
.DEFAULT_GOAL := all

# Alias for docker compose command that specifies projects docker-compose file
COMPOSE_FILE := srcs/docker-compose.yml
COMPOSE := docker compose -f $(COMPOSE_FILE)

# --- Inception environment variables ---------------------------------------------------------

# Bind mount host directories
DATA_DIR := /home/vpoka/data
DB_DIR := $(DATA_DIR)/database
WEB_DIR := $(DATA_DIR)/website

export DATA_DIR DB_DIR WEB_DIR

# --- Template files ---------------------------------------------------------

# Secret files
SECRETS_DIR := srcs/secrets
SECRETS :=	mariadb_root_password \
			mariadb_user_password \
			wordpress_admin_password \
			wordpress_user_password

define INCEPTION_ENV_TEMPLATE
# =============================================================================
# Inception environment file (srcs/.env)
# =============================================================================
# This file holds the non-sensitive configuration used by the services.
# Passwords are NOT set here; they live in docker secrets (srcs/secrets/).
#
# HOW THIS FILE WORKS
#   Every variable is commented out and pre-filled with its default value.
#   The defaults are declared in srcs/docker-compose.yml and apply whenever a
#   variable is left unset or empty here, so nothing has to be filled out to
#   run the project. To change a value, uncomment its line and edit it.
#
# REQUIRED (no default value)
#   WORDPRESS_DOMAIN is the only variable docker compose REQUIRES: when it is
#   unset or empty, compose aborts with an error instead of starting. It must
#   be set before the first start.
#
# FIRST START ONLY (baked into persistent storage)
#   All variables in the sections marked below are read only during the very
#   first start, while the project is being installed:
#     - MariaDB creates the database and its user from them.
#     - WordPress downloads its version and creates wp-config.php, the site
#       URL, the admin account and the extra user from them.
#   They are then baked into the persistent volumes (the host directories
#   DATA_DRIVE_PATH / WEB_DRIVE_PATH). Changing them afterwards has NO effect
#   on the installed project, and values out of sync with it will break it.
#   To change them for real, EVERYTHING must be deleted and reinstalled,
#   including all persistent storage:
#       make fclean      # removes .env, secrets and ALL persistent data
#       make setup
#       make
#
# SAFE TO CHANGE ANYTIME
#   The remaining variables (volume paths and WORDPRESS_FPM_PORT) are re-read
#   on every start, so they can be changed at any time.
# =============================================================================

# --- REQUIRED + FIRST START ONLY (no default: compose errors out if unset) ---
# Domain the site is served from (also add it to /etc/hosts, e.g.
# "127.0.0.1 vpoka.42.fr"). Written into the WordPress site URL at install.

# WORDPRESS_DOMAIN=vpoka.42.fr

# --- FIRST START ONLY: Database (baked into the database volume) -------------
# Used once, when MariaDB initialises its data volume and when WordPress
# generates wp-config.php.

# WORDPRESS_DB_NAME=wordpress
# WORDPRESS_DB_USER=wordpress
# WORDPRESS_DB_TABLE_PREFIX=wordpress_
# DB_CHARSET=utf8mb4
# DB_COLLATE=utf8mb4_uca1400_ai_ci

# --- FIRST START ONLY: WordPress install (baked into the web volume / DB) ----
# Used once, when WordPress downloads its core and installs itself.

# WORDPRESS_VERSION=7.0.4
# WORDPRESS_TITLE=Inception
# WORDPRESS_ADMIN_NAME=owner
# WORDPRESS_ADMIN_EMAIL=admin@invalid.email
# WORDPRESS_USER_NAME=author
# WORDPRESS_USER_EMAIL=author@invalid.email

# --- FIRST START ONLY: Ports (written into WordPress' configuration) ---------
# NGINX_PORT and MARIADB_PORT end up in the site URL / wp-config.php on first
# start, so changing them later requires the full wipe described above.

# NGINX_PORT=443
# MARIADB_PORT=3306

# --- SAFE TO CHANGE ANYTIME: applied on every (re)start ----------------------
# Volume paths (host paths of the persistent storage). Changing these points
# the project at a different (empty) host directory; already stored data
# simply stays in the old location.

# DATA_DRIVE_PATH=/home/vpoka/data/database
# WEB_DRIVE_PATH=/home/vpoka/data/website

# WORDPRESS_FPM_PORT is re-read by php-fpm, nginx and the healthchecks on
# every start, so it can be changed at any time.

# WORDPRESS_FPM_PORT=9000

endef
export INCEPTION_ENV_TEMPLATE

# --- Logging helpers ---------------------------------------------------------
# Colors
C_RESET  := \x1b[0m
C_CYAN   := \x1b[36m
C_YELLOW := \x1b[33m
C_BOLD   := \x1b[1m

# Banner announcing the target, e.g.  ==> up
# (uses $@, so no argument needed -> call with plain $(log_target))
define log_target
	@printf "$(C_BOLD)$(C_CYAN)==>$(C_RESET) $(C_BOLD)%s$(C_RESET)\n" "$@"
endef

# Prefix for sub-step messages within a target, e.g.      -> Building images
STEP_PREFIX := \t$(C_CYAN)->$(C_RESET)

# --- Default rules ----------------------------------
.PHONY: all clean fclean re up attached down start stop restart build pause unpause ps logs exec run setup setup-env setup-dirs setup-secrets rm-dirs rm-env rm-secrets help

all:
	$(log_target)
	@printf "$(STEP_PREFIX) Building and starting containers in detached mode\n"
	@$(COMPOSE) up --build -d

clean:
	$(log_target)
	@printf "$(STEP_PREFIX) Stopping and removing containers, networks, volumes and images\n"
	@$(COMPOSE) down --volumes --rmi all --remove-orphans

fclean: clean rm-env rm-secrets rm-dirs

re: clean all

# --- Docker compose rules ----------------------------------

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

# --- Extra rules ----------------------------------

setup: setup-env setup-dirs setup-secrets
	$(log_target)
	@printf '$(C_YELLOW)[WARNING] Before starting the services, please fill out:\n\t1. srcs/.env\n\t2. srcs/secrets/*.txt\n$(C_RESET)'

setup-env:
	$(log_target)
	@printf "$(STEP_PREFIX) Checking 'srcs/.env'\n"
	@if [ ! -f srcs/.env ]; then \
		echo -n "$$INCEPTION_ENV_TEMPLATE" > srcs/.env; \
		printf "$(STEP_PREFIX) created 'srcs/.env' from template\n"; \
	else \
		printf "$(STEP_PREFIX) 'srcs/.env' already exists\n"; \
	fi

setup-dirs:
	$(log_target)
	@printf "$(STEP_PREFIX) Creating host directories '$(DB_DIR)' and '$(WEB_DIR)'\n"
	@mkdir -p $(DB_DIR) $(WEB_DIR)

setup-secrets:
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
	@printf "$(STEP_PREFIX) Removing host data directory '$(DATA_DIR)'\n"
	@sudo rm -rf $(DATA_DIR)

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
	@printf "  - all           : (default) Build images and start containers in detached mode\n"
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
	@printf "  - setup         : Run all setup steps below\n"
	@printf "  - setup-env     : Generate srcs/.env from template (skips if exists)\n"
	@printf "  - setup-dirs    : Create host data directories\n"
	@printf "  - setup-secrets : Generate missing secret placeholder files\n"
	@printf "  -----\n"
	@printf "  - rm-dirs       : Remove host data directory\n"
	@printf "  - rm-env        : Remove srcs/.env\n"
	@printf "  - rm-secrets    : Remove secret files\n"
	@printf "  -----\n"
	@printf "  - help          : Display this help message\n"
