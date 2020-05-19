#!/usr/bin/env python

import requests as req
import json
import os
import docker

from cdb_utils import create_artifact, rchop, parse_cmd_line

DOCKER_IMAGE = "registry.gitlab.com/compliancedb/compliancedb/loancalculator"


def main():
    project_file = parse_cmd_line()

    print("Get the SHA for the docker image")
    client = docker.from_env()
    image = client.images.get(DOCKER_IMAGE)
    sha256_digest = image.attrs["RepoDigests"][0].split(":")[1]
    print("Found RepoDigest for latest docker image: " + sha256_digest)

    print("Publish to ComplianceDB")
    description = "Created by build " + os.getenv('BUILD_TAG', "UNDEFINED")
    git_commit = os.getenv('GIT_COMMIT', '0000000000000000000000000000000000000000')

    # https://github.com/meekrosoft/loan-calculator/commit/7e427b637d5120767692bff9602081871e3b387e
    # GIT_URL in jenkins is https://github.com/meekrosoft/loan-calculator.git
    # so we need to truncate off .git and add /commit/ + git_commit
    git_url = rchop(os.getenv('GIT_URL', "GIT_URL_UNDEFINED"), ".git")
    commit_url = git_url + "/commit/" + git_commit
    build_url = os.getenv('JOB_DISPLAY_URL', "BUILD_URL_UNDEFINED")
    print(os.getenv('IS_COMPLIANT', "FALSE"))
    is_compliant = os.getenv('IS_COMPLIANT', "FALSE") == "TRUE"

    with open(project_file) as project_file_contents:
        create_artifact(CDB_SERVER, project_file_contents, sha256_digest, DOCKER_IMAGE, description, git_commit, commit_url, build_url,
                    is_compliant)

if __name__ == '__main__':
    main()
