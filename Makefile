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

docker_pull:
	@docker pull ${IMAGE}

test:
	@docker run --name ${CONTAINER} --entrypoint ./test-entrypoint.sh ${IMAGE}
	@rm -rf build/test
	@mkdir -p build/test
	@docker cp ${CONTAINER}:/code/build/test/ $(PWD)/build
	@docker container rm ${CONTAINER}

security:
	@docker rm --force $@ 2> /dev/null || true
	@rm -rf build/security
	@mkdir -p build/security
	@docker run \
			--name $@ \
			--rm \
			--volume ${PWD}/build:/code/build \
			--entrypoint ./security-entrypoint.sh \
			${IMAGE}

coverage:
	@docker rm --force $@ 2> /dev/null || true
	@rm -rf build/coverage
	@mkdir -p build/coverage
	@docker run \
			--name $@ \
			--rm \
			--volume ${PWD}/build:/code/build \
			--entrypoint ./coverage-entrypoint.sh \
			${IMAGE}

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
			--env CDB_EVIDENCE_TYPE=${MERKELY_TEST_TYPE} \
			--rm \
			--volume ${PWD}/${MERKELYPIPE}:/Merkelypipe.json \
			--volume /var/run/docker.sock:/var/run/docker.sock \
			--volume ${PWD}/${MERKELY_TEST_RESULTS}:/data/junit/junit.xml \
			merkely/change python -m cdb.control_junit -p /Merkelypipe.json


merkely_log_coverage:
	docker run  \
		--env CDB_API_TOKEN=${MERKELY_API_TOKEN} \
		--env CDB_CI_BUILD_URL=${MERKELY_CI_BUILD_URL} \
		--env CDB_ARTIFACT_DOCKER_IMAGE=${IMAGE} \
		--env CDB_EVIDENCE_TYPE=coverage \
		--env CDB_IS_COMPLIANT=TRUE \
		--env CDB_DESCRIPTION="${COVERAGE_SUMMARY}" \
		--rm \
		--volume ${PWD}/${MERKELYPIPE}:/Merkelypipe.json \
		--volume=/var/run/docker.sock:/var/run/docker.sock \
		merkely/change python -m cdb.put_evidence -p /Merkelypipe.json


merkely_log_deployment:
	docker run \
        --env CDB_API_TOKEN=${MERKELY_API_TOKEN} \
        --env CDB_ARTIFACT_DOCKER_IMAGE=${IMAGE} \
        --env CDB_ENVIRONMENT=${MERKELY_ENVIRONMENT} \
        --env CDB_CI_BUILD_URL=${MERKELY_CI_BUILD_URL} \
        --env CDB_DESCRIPTION="${MERKELY_DESCRIPTION}" \
		--rm \
        --volume ${PWD}/${MERKELYPIPE}:/Merkelypipe.json \
        --volume /var/run/docker.sock:/var/run/docker.sock \
        merkely/change python -m cdb.create_deployment -p /Merkelypipe.json

merkely_create_approval:
	docker run \
			--env CDB_API_TOKEN=${MERKELY_API_TOKEN} \
			--env CDB_ARTIFACT_DOCKER_IMAGE=${IMAGE} \
			--env CDB_TARGET_SRC_COMMITISH=${MERKELY_TARGET_SOURCE_COMMITISH} \
			--env CDB_BASE_SRC_COMMITISH=${MERKELY_BASE_SOURCE_COMMITISH} \
			--env CDB_RELEASE_DESCRIPTION="${MERKELY_DESCRIPTION}" \
			--rm \
			--volume ${PWD}/${MERKELYPIPE}:/Merkelypipe.json \
			--volume /var/run/docker.sock:/var/run/docker.sock \
			--volume ${PWD}:/src \
			merkely/change python -m cdb.create_release -p /Merkelypipe.json


# Re-validate targets below this comment

run: build
	@docker run --rm  --name ${CONTAINER} ${IMAGE}




