# --- Variables ---------------------------------------------------------
.DEFAULT_GOAL := all

# Alias for docker compose command that specifies projects docker-compose file
COMPOSE_FILE := srcs/docker-compose.yml
COMPOSE := docker compose -f $(COMPOSE_FILE)

# --- Inception environment variables ---------------------------------------------------------

# Bind mount host directories
DATA_DIR := /home/$(USER)/inception-data
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
# These are all the variables that are used throughout the services.
# Passwords are stored in docker secrets (see srcs/secrets), so this file only holds non-sensitive configuration.
#
# All of the variables are commented out and filled with their default value.
# The defaults are declared in srcs/docker-compose.yml, which uses them whenever a
# variable is unset or empty here, so nothing has to be filled out to run the project.
# If you wish to change them, uncomment the values and change them with whatever you want them to be.

## Ports
# NGINX_PORT=443
# WORDPRESS_FPM_PORT=9000
# MARIADB_PORT=3306

## Database related
# WORDPRESS_DB_NAME=wordpress
# WORDPRESS_DB_USER=wordpress
# WORDPRESS_DB_TABLE_PREFIX=wordpress_
# DB_CHARSET=utf8mb4
# DB_COLLATE=utf8mb4_uca1400_ai_ci

## Wordpress related
# WORDPRESS_DOMAIN=vpoka.42.fr
# WORDPRESS_TITLE=Inception
# WORDPRESS_ADMIN_NAME=owner
# WORDPRESS_ADMIN_EMAIL=admin@invalid.email
# WORDPRESS_USER_NAME=user
# WORDPRESS_USER_EMAIL=user@invalid.email

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
.PHONY: all clean fclean re up down start stop restart build pause unpause ps logs setup setup-env setup-dirs setup-secrets distclean rm-dirs rm-env rm-secrets help

all: up

clean: down
	$(log_target)
	@printf "$(STEP_PREFIX) Removing stopped containers\n"
	@$(COMPOSE) rm -f

fclean: clean
	$(log_target)
	@printf "$(STEP_PREFIX) Removing: containers + volumes + images\n"
	@$(COMPOSE) down --volumes --rmi all #>/dev/null

re: fclean all

# --- Docker compose rules ----------------------------------

up:
	$(log_target)
	@printf "$(STEP_PREFIX) Building and starting containers in detached mode\n"
	@$(COMPOSE) up --build

detached:
	$(log_target)
	@printf "$(STEP_PREFIX) Building and starting containers in detached mode\n"
	@$(COMPOSE) up --build -d

build:
	$(log_target)
	@printf "$(STEP_PREFIX) Building service images\n"
	@$(COMPOSE) build

start:
	$(log_target)
	@printf "$(STEP_PREFIX) Starting existing containers\n"
	@$(COMPOSE) start

stop:
	$(log_target)
	@printf "$(STEP_PREFIX) Stopping running containers\n"
	@$(COMPOSE) stop

restart:
	$(log_target)
	@printf "$(STEP_PREFIX) Restarting containers\n"
	@$(COMPOSE) restart

down:
	$(log_target)
	@printf "$(STEP_PREFIX) Stopping and removing containers\n"
	@$(COMPOSE) down

pause:
	$(log_target)
	@printf "$(STEP_PREFIX) Pausing all servives\n"
	@$(COMPOSE) pause

unpause:
	$(log_target)
	@printf "$(STEP_PREFIX) Resuming all services\n"
	@$(COMPOSE) unpause

ps:
	$(log_target)
	@$(COMPOSE) ps -a

logs:
	$(log_target)
	@$(COMPOSE) logs

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

distclean: fclean rm-dirs rm-env rm-secrets

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
	@printf "  - all           : (default) Run setup then build and start containers"
	@printf "  - clean         : Stop containers and remove orphans"
	@printf "  - fclean        : Remove containers, images, volumes and orphans (keeps host data and .env)"
	@printf "  - re            : Full rebuild: fclean then all"
	@printf "$(C_BOLD)- Docker compose commands$(C_RESET) %s\n"
	@printf "  - up            : Build and start containers in detached mode"
	@printf "  - down          : Stop and remove containers"
	@printf "  - start         : Start existing containers"
	@printf "  - stop          : Stop running containers"
	@printf "  - pause         : Pause all services"
	@printf "  - unpause       : Unpause all services"
	@printf "  - build         : Build or rebuild services"
	@printf "  - ps            : List running containers"
	@printf "  - logs          : View output of containers"
	@printf "$(C_BOLD)- Extra commands$(C_RESET) %s\n"
	@printf "  - setup         : Run all setup steps below"
	@printf "  - setup-env     : Generate srcs/.env from template (skips if exists)"
	@printf "  - setup-dirs    : Create host data directories"
	@printf "  - setup-secrets : Generate missing secret placeholder files"
	@printf "  -----"
	@printf "  - distclean     : fclean + remove host data and config (!all persistent data lost!)"
	@printf "  - rm-dirs       : Remove host data directory"
	@printf "  - rm-env        : Remove srcs/.env"
	@printf "  - rm-secrets    : Remove secret files"
	@printf "  -----"
	@printf "  - help          : Display this help message"
