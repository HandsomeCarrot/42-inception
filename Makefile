COMPOSE := docker compose
COMPOSE_FILE := srcs/docker-compose.yml

.PHONY: all up down start stop build logs ps clean fclean re
.DEFAULT_GOAL := all

all: up

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

clean:
	$(COMPOSE) -f $(COMPOSE_FILE) down --remove-orphans

fclean:
	$(COMPOSE) -f $(COMPOSE_FILE) down --rmi all --volumes --remove-orphans

re: fclean all
