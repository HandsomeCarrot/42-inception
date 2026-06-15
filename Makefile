COMPOSE := docker compose
COMPOSE_FILE := srcs/docker-compose.yml

.PHONY: all clean fclean re up down start stop build ps help
.DEFAULT_GOAL := all

all: up

clean:
	$(COMPOSE) -f $(COMPOSE_FILE) down --remove-orphans

fclean:
	$(COMPOSE) -f $(COMPOSE_FILE) down --rmi all --volumes --remove-orphans

re: fclean all

up:
	$(COMPOSE) -f $(COMPOSE_FILE) up -d --build

build:
	$(COMPOSE) -f $(COMPOSE_FILE) build

start:
	$(COMPOSE) -f $(COMPOSE_FILE) start

stop:
	$(COMPOSE) -f $(COMPOSE_FILE) stop

down:
	$(COMPOSE) -f $(COMPOSE_FILE) down

ps:
	$(COMPOSE) -f $(COMPOSE_FILE) ps

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
