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
	@docker stop $(docker ps -qa)
	@docker rm $(docker ps -qa)
	@docker rmi -f $(docker images -qa)
	@docker volume rm $(docker volume ls -q)
	@docker network rm $(docker network ls -q)

re: stop start

rebuild: down all

.PHONY: all host stop start build prune re rebuild
