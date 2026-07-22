COMPOSE_FILE := srcs/docker-compose.yml
COMPOSE := docker compose -f $(COMPOSE_FILE)

# Bind mount host directories (must match docker-compose.yml)
DATA_DIR := /home/viktor/data
DB_DIR := $(DATA_DIR)/database
WEB_DIR := $(DATA_DIR)/website

define ENV_TEMPLATE
DOMAIN_NAME=

# Mariadb config
DB_ROOT_PASSWORD=
DB_NAME=
DB_USER=
DB_PASSWORD=
endef
export ENV_TEMPLATE

.PHONY: all clean fclean re up down start stop restart build pause unpause ps logs setup distclean help
.DEFAULT_GOAL := all

# --- Logging helpers ---------------------------------------------------------
# Colors
C_RESET := \x1b[0m
C_CYAN  := \x1b[36m
C_BOLD  := \x1b[1m

# Banner announcing the target, e.g.  ==> up
# (uses $@, so no argument needed -> call with plain $(log_target))
define log_target
	@printf "$(C_BOLD)$(C_CYAN)==>$(C_RESET) $(C_BOLD)%s$(C_RESET)\n" "$@"
endef
# Sub-step within a target, e.g.     -> Building images
# (takes the message as $(1) -> call with $(call log_step,message))
define log_step
	@printf "$(C_CYAN)   ->$(C_RESET) %s\n" "$(1)"
endef

# --- Default rules ----------------------------------

all: up

clean: down
	$(log_target)
	$(call log_step,Removing stopped containers)
	@$(COMPOSE) rm -f

fclean: clean
	$(log_target)
	$(call log_step,Removing: containers + volumes + images)
	@$(COMPOSE) down --volumes --rmi all #>/dev/null

re: fclean all

# --- Docker compose rules ----------------------------------

up:
	$(log_target)
	$(call log_step,Building and starting containers in detached mode)
	@$(COMPOSE) up --build -d

build:
	$(log_target)
	$(call log_step,Building service images)
	@$(COMPOSE) build

start:
	$(log_target)
	$(call log_step,Starting existing containers)
	@$(COMPOSE) start

stop:
	$(log_target)
	$(call log_step,Stopping running containers)
	@$(COMPOSE) stop

restart:
	$(log_target)
	$(call log_step,Restarting containers)
	@$(COMPOSE) restart

down:
	$(log_target)
	$(call log_step,Stopping and removing containers)
	@$(COMPOSE) down

pause:
	$(log_target)
	$(call log_step,Pausing all servives)
	@$(COMPOSE) pause

unpause:
	$(log_target)
	$(call log_step,Resuming all services)
	@$(COMPOSE) unpause

ps:
	$(log_target)
	@$(COMPOSE) ps

logs:
	$(log_target)
	@$(COMPOSE) logs

# --- Extra rules ----------------------------------

setup:
	$(log_target)
	$(call log_step,Checking srcs/.env)
	@if [ ! -f srcs/.env ]; then \
		echo "$$ENV_TEMPLATE" > srcs/.env; \
		printf "$(C_CYAN)   ->$(C_RESET) wrote srcs/.env from template\n"; \
		printf "$(C_CYAN)   ->$(C_RESET) fill in srcs/.env, then run make again\n"; \
	else \
		printf "$(C_CYAN)   ->$(C_RESET) srcs/.env already exists, skipping\n"; \
	fi
	$(call log_step,Creating host directories $(DB_DIR) and $(WEB_DIR))
	@mkdir -p $(DB_DIR) $(WEB_DIR)

distclean: fclean
	$(log_target)
	$(call log_step,Removing host data directory $(DATA_DIR))
	@sudo rm -rf $(DATA_DIR)
	$(call log_step,Removing srcs/.env)
	@rm -f srcs/.env

help:
	@echo "Available targets:"
	@echo "- Standard commands"
	@echo "  - all       - (default) Run setup then build and start containers"
	@echo "  - clean     - Stop containers and remove orphans"
	@echo "  - fclean    - Remove containers, images, volumes and orphans (keeps host data and .env)"
	@echo "  - re        - Full rebuild: fclean then all"
	@echo "- Docker compose commands"
	@echo "  - up        - Build and start containers in detached mode"
	@echo "  - down      - Stop and remove containers"
	@echo "  - start     - Start existing containers"
	@echo "  - stop      - Stop running containers"
	@echo "  - pause     - Pause all services"
	@echo "  - unpause   - Unpause all services"
	@echo "  - build     - Build or rebuild services"
	@echo "  - ps        - List running containers"
	@echo "  - logs      - View output of containers"
	@echo "- Extra commands"
	@echo "  - setup     - Create host data directories and generate srcs/.env template (skips if already exists)"
	@echo "  - distclean - fclean + remove host data directory and srcs/.env (!all persistent data and credentials will be lost!)"
	@echo "  - help      - Display this help message"
