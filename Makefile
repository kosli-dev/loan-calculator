APP    := loancalculator
CONTAINER := merkely_loancalculator_1
REPOSITORY   := merkely/${APP}
TAG    := $$(git log -1 --pretty=%h)
SERVER_PORT := 8002
MERKELYPIPE=Merkelypipe.json

ifdef TAGGED_IMAGE
IMAGE := ${TAGGED_IMAGE}
else
IMAGE  := ${REPOSITORY}:${TAG}
endif

ifdef UNTAGGED_IMAGE
LATEST := ${UNTAGGED_IMAGE}:latest
else
LATEST := ${REPOSITORY}:latest
endif


# list the targets
.PHONY: list build coverage test
list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs


build:
	@echo ${IMAGE}
	@docker build -f Dockerfile -t ${IMAGE} .
	@docker tag ${IMAGE} ${LATEST}


run: build
	@docker run --rm  --name ${CONTAINER} ${IMAGE}


test:
	@docker container rm --force $@ 2> /dev/null || true
	@docker run \
		--name $@ \
		--entrypoint ./entrypoint-test.sh \
		${IMAGE}
	@rm -rf build/test
	@mkdir -p build/test
	@docker cp $@:/code/build/test/ $(PWD)/build


security:
	@docker container rm --force $@ 2> /dev/null || true
	@rm -rf build/security
	@mkdir -p build/security
	@docker run \
			--name $@ \
			--rm \
			--volume ${PWD}/build:/code/build \
			--entrypoint ./entrypoint-security.sh \
			${IMAGE}


coverage:
	@docker container rm --force $@ 2> /dev/null || true
	@rm -rf build/coverage
	@mkdir -p build/coverage
	@docker run \
			--name $@ \
			--rm \
			--volume ${PWD}/build:/code/build \
			--entrypoint ./entrypoint-coverage.sh \
			${IMAGE}


branch:
	@echo Branch is ${BRANCH_NAME}
	@echo MERKELYPIPE is ${MERKELYPIPE}


docker_login:
	@echo ${DOCKERHUB_DEPLOY_TOKEN} | docker login --username ${DOCKERHUB_DEPLOY_USERNAME} --password-stdin


docker_push:
	@docker push ${IMAGE}
	@docker push ${LATEST}


docker_pull:
	@docker pull ${IMAGE}

# - - - - - - - - - - - - - - - - - - - - - - - - - - -

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
		--env MERKELY_FINGERPRINT=${MERKELY_FINGERPRINT} \
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
		--env MERKELY_COMMAND=log_test \
		--env MERKELY_FINGERPRINT=${MERKELY_FINGERPRINT} \
		--env MERKELY_EVIDENCE_TYPE=${MERKELY_EVIDENCE_TYPE} \
		--env MERKELY_CI_BUILD_URL=${MERKELY_CI_BUILD_URL} \
		--env MERKELY_API_TOKEN=${MERKELY_API_TOKEN} \
		--rm \
		--volume ${PWD}/${TEST_RESULTS_FILE}:/data/junit/junit.xml \
		--volume ${PWD}/${MERKELYPIPE}:/Merkelypipe.json \
		--volume /var/run/docker.sock:/var/run/docker.sock \
		merkely/change


merkely_log_evidence:
	docker run \
        --env MERKELY_COMMAND=log_evidence \
        --env MERKELY_FINGERPRINT=${MERKELY_FINGERPRINT} \
        --env MERKELY_EVIDENCE_TYPE=${MERKELY_EVIDENCE_TYPE} \
        --env MERKELY_IS_COMPLIANT=${MERKELY_IS_COMPLIANT} \
        --env MERKELY_DESCRIPTION="${MERKELY_DESCRIPTION}" \
        --env MERKELY_CI_BUILD_URL=${MERKELY_CI_BUILD_URL} \
        --env MERKELY_API_TOKEN=${MERKELY_API_TOKEN} \
        --rm \
        --volume=/var/run/docker.sock:/var/run/docker.sock \
        --volume ${PWD}/${MERKELYPIPE}:/Merkelypipe.json \
        merkely/change


merkely_log_deployment:
	docker run \
        --env MERKELY_COMMAND=log_deployment \
        --env MERKELY_FINGERPRINT=${MERKELY_FINGERPRINT} \
        --env MERKELY_CI_BUILD_URL=${MERKELY_CI_BUILD_URL} \
        --env MERKELY_DESCRIPTION="${MERKELY_DESCRIPTION}" \
        --env MERKELY_ENVIRONMENT=${MERKELY_ENVIRONMENT} \
        --env MERKELY_USER_DATA=${MERKELY_USER_DATA} \
        --env MERKELY_API_TOKEN=${MERKELY_API_TOKEN} \
        --rm \
        --volume=/var/run/docker.sock:/var/run/docker.sock \
        --volume ${PWD}/${MERKELYPIPE}:/Merkelypipe.json \
        merkely/change


merkely_log_approval:
	docker run \
		--env MERKELY_COMMAND=log_approval \
		--env MERKELY_FINGERPRINT=${MERKELY_FINGERPRINT} \
		--env MERKELY_TARGET_SRC_COMMITISH=${MERKELY_TARGET_SRC_COMMITISH} \
		--env MERKELY_BASE_SRC_COMMITISH=${MERKELY_BASE_SRC_COMMITISH} \
		--env MERKELY_DESCRIPTION="${MERKELY_DESCRIPTION}" \
		--env MERKELY_IS_APPROVED="${MERKELY_IS_APPROVED}" \
		--env MERKELY_SRC_REPO_ROOT=${MERKELY_SRC_REPO_ROOT} \
		--env MERKELY_API_TOKEN=${MERKELY_API_TOKEN} \
		--rm \
		--volume=/var/run/docker.sock:/var/run/docker.sock \
		--volume ${PWD}:/src \
		--volume ${PWD}/${MERKELYPIPE}:/Merkelypipe.json \
		merkely/change


merkely_control_deployment:
	docker run \
		--env MERKELY_COMMAND=control_deployment \
		--env MERKELY_FINGERPRINT=${MERKELY_FINGERPRINT} \
		--env MERKELY_API_TOKEN=${MERKELY_API_TOKEN} \
		--rm \
		--volume ${PWD}/${MERKELYPIPE}:/Merkelypipe.json \
		--volume /var/run/docker.sock:/var/run/docker.sock \
		merkely/change




