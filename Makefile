ENV_FILE = $(PWD)/srcs/.env
DC_FILE = $(PWD)/srcs/docker-compose.yml

# Check if the .env file exists using shell command
ifneq ("$(shell [ -f $(ENV_FILE) ] && echo exists)", "exists")
  $(error ".env file not found at $(ENV_FILE)")
endif

include $(ENV_FILE)

all: host build start

host:
	@if ! grep -q "127.0.0.1 ${DOMAIN_NAME}" /etc/hosts; then \
	    echo "Adding host to /etc/hosts"; \
	    echo "127.0.0.1 ${DOMAIN_NAME}" >> /etc/hosts; \
	else \
	    echo "Host entry already exists. Skipping..."; \
	fi

stop:
	@echo "Stopping all containers"
	@docker-compose -f $(DC_FILE) stop

down:
	@echo "Stopping and removing all containers, networks, images, and volumes"
	@docker-compose -f $(DC_FILE) down
	@docker volume rm ${DOCKER_DB_VOLUME} ${DOCKER_SHARED_VOLUME} --force

start:
	@echo "Starting all containers"
	@docker-compose -f $(DC_FILE) up -d

build:
	@echo "Building all containers"
	@docker-compose -f $(DC_FILE) build

prune: down
	@echo "Pruning docker system for a clean start"
	@docker system prune -f

re: stop start

rebuild: down all

.PHONY: all host stop start build prune re rebuild
