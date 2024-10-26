ENV_FILE = $(PWD)/srcs/.env
DC_FILE = $(PWD)/srcs/docker-compose.yml

# Check if the .env file exists using shell command
ifneq ("$(shell [ -f $(ENV_FILE) ] && echo exists)", "exists")
  $(error ".env file not found at $(ENV_FILE)")
endif

include $(ENV_FILE)

all: host build start

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all        - Build and start all containers"
	@echo "  host       - Add domain name to /etc/hosts"
	@echo "  stop       - Stop all containers"
	@echo "  down       - Stop and remove all containers, networks, images, and volumes"
	@echo "  start      - Start all containers"
	@echo "  build      - Build all containers"
	@echo "  prune      - Prune docker system for a clean start"
	@echo "  kill       - Stop and remove all containers, images, and volumes"
	@echo "  rm-volumes - Remove specified Docker volumes and their paths"
	@echo "  re         - Stop and start all containers"
	@echo "  rebuild    - Stop, remove, build, and start all containers in the system"
	@echo ""

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
	@rm -rf $(DOCKER_DB_VOLUME_PATH) $(DOCKER_SHARED_VOLUME_PATH)

start:
	@echo "Starting all containers"
	@docker-compose -f $(DC_FILE) up -d

build:
	@echo "Creating volume directories if they don't exist"
	@mkdir -p $(DOCKER_DB_VOLUME_PATH) $(DOCKER_SHARED_VOLUME_PATH)
	@echo "Building all containers"
	@docker-compose -f $(DC_FILE) build

prune: down
	@echo "Pruning docker system for a clean start"
	@docker system prune -f

kill:
	@echo "Stopping all containers"
	@docker stop $(shell docker ps -qa)
	@echo "Removing all containers"
	@docker rm $(shell docker ps -qa)
	@echo "Removing all images"
	@docker rmi -f $(shell docker images -qa)
	@echo "Removing all volumes"
	@docker volume rm $(shell docker volume ls -q)
	@echo "Removing all networks"
	@docker network rm $(shell docker network ls -q)

rm-volumes:
	@echo "Removing specified Docker volumes and their paths"
	@docker volume rm ${DOCKER_DB_VOLUME} ${DOCKER_SHARED_VOLUME} --force
	@rm -rf $(DOCKER_DB_VOLUME_PATH) $(DOCKER_SHARED_VOLUME_PATH)

re: stop start

rebuild: down all

check-env:
	@echo "Checking required environment variables..."
	@if [ -z "$(DOMAIN_NAME)" ]; then \
	    echo "DOMAIN_NAME is not set in .env"; exit 1; \
	fi
	@if [ -z "$(DOCKER_DB_VOLUME)" ] || [ -z "$(DOCKER_SHARED_VOLUME)" ]; then \
	    echo "DOCKER_DB_VOLUME or DOCKER_SHARED_VOLUME is not set in .env"; exit 1; \
	fi
	@if [ -z "$(DOCKER_DB_VOLUME_PATH)" ] || [ -z "$(DOCKER_SHARED_VOLUME_PATH)" ]; then \
	    echo "DOCKER_DB_VOLUME_PATH or DOCKER_SHARED_VOLUME_PATH is not set in .env"; exit 1; \
	fi

.PHONY: all host stop start build prune re rebuild check-env rm-volumes
