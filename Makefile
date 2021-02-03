APP    := loancalculator
CONTAINER := merkely_loancalculator_1
REPOSITORY   := merkely/${APP}
TAG    := $$(git log -1 --pretty=%h)
IMAGE  := ${REPOSITORY}:${TAG}
LATEST := ${REPOSITORY}:latest
SERVER_PORT := 8002
MERKELYPIPE=Merkelypipe.json


# all non-latest images - for prune target
IMAGES := $(shell docker image ls --format '{{.Repository}}:{{.Tag}}' | grep $(REPOSITORY) | grep -v latest)

# list the targets: from https://stackoverflow.com/questions/4219255/how-do-you-get-the-list-of-targets-in-a-makefile
.PHONY: list build coverage test
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
	@echo MERKELYPIPE is ${MERKELYPIPE}


docker_login:
	@echo ${DOCKER_DEPLOY_TOKEN} | docker login --username ${DOCKER_DEPLOY_USERNAME} --password-stdin

docker_push:
	@docker push ${IMAGE}
	@docker push ${LATEST}

test:
	@docker run --name ${CONTAINER} --entrypoint ./test-entrypoint.sh ${IMAGE}
	@rm -rf build/test
	@mkdir -p build/test
	@docker cp ${CONTAINER}:/code/build/test/ $(PWD)/build
	@docker container rm ${CONTAINER}


merkely_declare_pipeline:
	docker run --rm \
			--env MERKELY_COMMAND=declare_pipeline \
			--env MERKELY_API_TOKEN=${MERKELY_API_TOKEN} \
			--env MERKELY_HOST=https://app.compliancedb.com \
			--volume ${PWD}/${MERKELYPIPE}:/Merkelypipe.json \
			merkely/change

merkely_log_artifact:
	docker run \
			--env MERKELY_COMMAND=log_artifact \
			--env MERKELY_FINGERPRINT="docker://${IMAGE}" \
			--env MERKELY_DISPLAY_NAME=${IMAGE} \
			--env MERKELY_IS_COMPLIANT="TRUE" \
			--env MERKELY_ARTIFACT_GIT_URL=${MERKELY_ARTIFACT_GIT_URL} \
			--env MERKELY_ARTIFACT_GIT_COMMIT=${MERKELY_ARTIFACT_GIT_COMMIT} \
			--env MERKELY_CI_BUILD_URL=${MERKELY_CI_BUILD_URL} \
			--env MERKELY_CI_BUILD_NUMBER=${MERKELY_CI_BUILD_NUMBER} \
			--env MERKELY_API_TOKEN=${MERKELY_API_TOKEN} \
			--env MERKELY_HOST=https://app.compliancedb.com \
			--rm \
			--volume ${PWD}/${MERKELYPIPE}:/Merkelypipe.json \
			--volume=/var/run/docker.sock:/var/run/docker.sock \
			merkely/change

merkely_log_test:
	docker run \
			--env CDB_API_TOKEN=${MERKELY_API_TOKEN} \
			--env CDB_CI_BUILD_URL=${MERKELY_CI_BUILD_URL} \
			--env CDB_ARTIFACT_DOCKER_IMAGE=${IMAGE} \
			--env CDB_EVIDENCE_TYPE=unit_test \
			--rm \
			--volume ${PWD}/${MERKELYPIPE}:/Merkelypipe.json \
			--volume=/var/run/docker.sock:/var/run/docker.sock \
			--volume ${PWD}/build/test/pytest_unit.xml:/data/junit/junit.xml \
			merkely/change python -m cdb.control_junit -p /Merkelypipe.json


# Re-validate targets below this comment



add_evidence: ensure_network
	docker run --rm --name ${CONTAINER} --volume=/var/run/docker.sock:/var/run/docker.sock --network cdb_net \
	        --workdir=/code/cdb \
	        --env IS_COMPLIANT=${IS_COMPLIANT} \
	        --env EVIDENCE_TYPE=${EVIDENCE_TYPE} \
	        --env DESCRIPTION="${DESCRIPTION}" \
	        --env BUILD_TAG=${BUILD_TAG} \
	        --env URL=${URL} \
	        --entrypoint python \
	        ${IMAGE} add_evidence.py -p ${MERKELYPIPE}

ensure_review: ensure_network
	docker run --rm --name ${CONTAINER} --volume=/var/run/docker.sock:/var/run/docker.sock --network cdb_net \
	        --workdir=/code/cdb \
	        --env IS_COMPLIANT=${IS_COMPLIANT} \
	        --env EVIDENCE_TYPE=${EVIDENCE_TYPE} \
	        --env DESCRIPTION="${DESCRIPTION}" \
	        --env BUILD_TAG=${BUILD_TAG} \
	        --env URL=${URL} \
	        --entrypoint python \
	        ${IMAGE} add_evidence.py -p ${MERKELYPIPE}


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

run: build
	@docker run --rm  --name ${CONTAINER} ${IMAGE}




