COMPOSE_FILE := srcs/docker-compose.yml
COMPOSE := docker compose -f $(COMPOSE_FILE)

# Bind mount host directories (must match docker-compose.yml)
DATA_DIR := /home/viktor/data
DB_DIR := $(DATA_DIR)/database
WEB_DIR := $(DATA_DIR)/website

.PHONY: all clean fclean re up down start stop restart build ps logs env help
.DEFAULT_GOAL := all

all: up

up:
	mkdir -p $(DB_DIR) $(WEB_DIR)
	$(COMPOSE) up --build #-d # TODO: add this flag for final version

build:
	$(COMPOSE) build

start:
	$(COMPOSE) start

stop:
	$(COMPOSE) stop

restart:
	$(COMPOSE) restart

down:
	$(COMPOSE) down

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs

clean: down
	$(COMPOSE) rm -f

fclean: down
	$(COMPOSE) down --volumes --remove-orphans --rmi all
	sudo rm -rf $(DATA_DIR)
	rm -f ./srcs/.env

re: fclean all

define ENV_TEMPLATE
DOMAIN_NAME=

# Mariadb config
DB_ROOT_PASSWORD=
DB_NAME=
DB_USER=
DB_PASSWORD=
endef
export ENV_TEMPLATE

env:
	@echo "$$ENV_TEMPLATE" > srcs/.env
	@printf "\x1b[32mCreated template '.env' file in 'srcs/'\x1b[0m\n"

help:
	@echo "Available targets:"
	@echo "  all       - (default) Full setup: build and start containers"
	@echo "  up        - Build and start containers in detached mode"
	@echo "  down      - Stop and remove containers"
	@echo "  start     - Start existing containers"
	@echo "  stop      - Stop running containers"
	@echo "  build     - Build or rebuild services"
	@echo "  ps        - List running containers"
	@echo "  clean     - Stop containers and remove orphans"
	@echo "  fclean    - Full cleanup: remove containers, images, volumes, orphans"
	@echo "  re        - Full rebuild: fclean then all"
	@echo "  env       - Generate a .env file with all variables needed decalred (!overwrites the file if it existed!)"
	@echo "  help      - Display this help message"
