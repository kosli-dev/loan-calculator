APP    := loancalculator
CONTAINER := compliancedb_loancalculator_1
REPOSITORY   := registry.gitlab.com/compliancedb/compliancedb/${APP}
TAG    := $$(git log -1 --pretty=%h)
IMAGE  := ${REPOSITORY}:${TAG}
LATEST := ${REPOSITORY}:latest
SERVER_PORT := 8002

#ifeq ($(BRANCH_NAME),master)

MASTER_BRANCH := master
# Check if branch ends with master, i.e. match origin/master AND master
ifeq ($(patsubst %$(MASTER_BRANCH),,$(lastword $(BRANCH_NAME))),)
	IS_MASTER=TRUE
	PROJFILE=project-master.json
else
	IS_MASTER=FALSE
	PROJFILE=project-pull-requests.json
endif


# all non-latest images - for prune target
IMAGES := $(shell docker image ls --format '{{.Repository}}:{{.Tag}}' | grep $(REPOSITORY) | grep -v latest)

# list the targets: from https://stackoverflow.com/questions/4219255/how-do-you-get-the-list-of-targets-in-a-makefile
.PHONY: list build coverage
list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs

ensure_network:
	docker network inspect cdb_net &>/dev/null || docker network create --driver bridge cdb_net

build:
	@echo ${IMAGE}
	@docker build -f Dockerfile -t ${IMAGE} .
	@docker tag ${IMAGE} ${LATEST}


branch:
	@echo Branch is ${BRANCH_NAME}
	@echo IS_MASTER is ${IS_MASTER}
	@echo PROJFILE is ${PROJFILE}

push:
	@docker push ${IMAGE}
	@docker push ${LATEST}

test: ensure_network
	@docker run --rm -p ${SERVER_PORT}:${SERVER_PORT} --name ${CONTAINER} --entrypoint pytest ${IMAGE} -rA --ignore=integration_tests --capture=no --cov=src -v

ensure_project: ensure_network
	docker run --rm --name ${CONTAINER} --network cdb_net --workdir=/code/cdb --entrypoint python ${IMAGE} ensure_project.py -p ${PROJFILE}


publish_artifact: ensure_network
	docker run --rm --name ${CONTAINER} --volume=/var/run/docker.sock:/var/run/docker.sock --network cdb_net \
	        --workdir=/code/cdb \
	        --env IS_COMPLIANT=${IS_COMPLIANT} \
	        --env GIT_URL=${GIT_URL} \
	        --env GIT_COMMIT=${GIT_COMMIT} \
	        --env JOB_DISPLAY_URL=${JOB_DISPLAY_URL} \
	        --env BUILD_TAG=${BUILD_TAG} \
	        --entrypoint python \
	        ${IMAGE} publish_artifact.py -p ${PROJFILE}


security:
	@docker run -p ${SERVER_PORT}:${SERVER_PORT} --name ${CONTAINER} --entrypoint ./security-entrypoint.sh ${IMAGE}
	@rm -rf build/security
	@mkdir -p build/security
	@docker cp ${CONTAINER}:/code/build/security/ $(PWD)/build
	@docker container rm ${CONTAINER}

coverage:
	@docker run -p ${SERVER_PORT}:${SERVER_PORT} --name ${CONTAINER} --entrypoint ./coverage-entrypoint.sh ${IMAGE}
	@rm -rf build/coverage
	@mkdir -p build/coverage
	@docker cp ${CONTAINER}:/code/build/coverage/ $(PWD)/build
	@docker container rm ${CONTAINER}

debug: ensure_network
	@docker run --rm -p ${SERVER_PORT}:${SERVER_PORT} --name ${CONTAINER} -it --entrypoint sh ${IMAGE}

run: build
	@docker run --rm  --name ${CONTAINER} ${IMAGE}

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
	pytest --capture=no


ci: build test push
	@echo "Building testing pushing"
