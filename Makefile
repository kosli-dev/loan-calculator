APP    := integrations
CONTAINER := compliancedb_integrations_1
REPOSITORY   := registry.gitlab.com/compliancedb/compliancedb/${APP}
TAG    := $$(git log -1 --pretty=%h)
IMAGE  := ${REPOSITORY}:${TAG}
LATEST := ${REPOSITORY}:latest
SERVER_PORT := 8002

# all non-latest images - for prune target
IMAGES := $(shell docker image ls --format '{{.Repository}}:{{.Tag}}' | grep $(REPOSITORY) | grep -v latest)

# list the targets: from https://stackoverflow.com/questions/4219255/how-do-you-get-the-list-of-targets-in-a-makefile
.PHONY: list
list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs


build:
	@echo ${IMAGE}
	@docker build -f Dockerfile -t ${IMAGE} .
	@docker tag ${IMAGE} ${LATEST}

push:
	@docker push ${IMAGE}
	@docker push ${LATEST}

test: ensure_network
	@docker run --rm -p ${SERVER_PORT}:${SERVER_PORT} --name ${CONTAINER} --entrypoint pytest ${IMAGE} -rA --ignore=integration_tests --capture=no --cov=app -v


coverage:
	@docker run -p ${SERVER_PORT}:${SERVER_PORT} --name ${CONTAINER} --entrypoint ./entrypoint.sh ${IMAGE}
	@docker cp ${CONTAINER}:/app/server/htmlcov /tmp/coverage
	@docker container rm ${CONTAINER}

debug: ensure_network
	@docker run --rm -p ${SERVER_PORT}:${SERVER_PORT} --name ${CONTAINER} -it --entrypoint sh ${IMAGE}

run: build
	@echo Try this:
	@echo docker run --rm  --name ${CONTAINER} ${IMAGE}

# Run without tests
cowboy: ensure_network
	@docker run --rm -p ${SERVER_PORT}:${SERVER_PORT} --name ${CONTAINER} ${IMAGE}

# Enter running container
enter:
	@docker exec -ti ${CONTAINER} sh

# Delete all the non-latest images
prune:
	@docker image rm $(IMAGES)

clean:
	@echo cleaning ${IMAGE}
	@docker image rm ${LATEST}
	@docker image rm ${IMAGE}

clean_all:
	@echo Nuking all compliancedb images
	@docker image rm -f $$(docker image ls | grep compliancedb | tail -r | tr -s ' ' |  cut -d ' ' -f 3)

test_in_docker:
	pytest --ignore=integration_tests --capture=no


ci: build test push
	@echo "Building testing pushing"
