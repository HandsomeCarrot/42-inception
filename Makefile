COMPOSE_FILE := srcs/docker-compose.yml
COMPOSE := docker compose -f $(COMPOSE_FILE)

.PHONY: all clean fclean re up down start stop restart build ps logs help
.DEFAULT_GOAL := all

all: up

up:
	$(COMPOSE) up --build #-d # TODO: add this flag forfinal version

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

clean:
	$(COMPOSE) down --remove-orphans

fclean:
	$(COMPOSE) down --rmi all --volumes --remove-orphans

re: fclean all

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
	@echo "  help      - Display this help message"
