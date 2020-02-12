#!/usr/bin/env python

import requests as req
import json
import os
import docker

from cdb_utils import create_artifact, rchop, parse_cmd_line, add_evidence

DOCKER_IMAGE = "registry.gitlab.com/compliancedb/compliancedb/loancalculator"


def main():
    # TODO parameterize later
    host = "http://hub"
    project_file = parse_cmd_line()

    print("Get the SHA for the docker image")
    client = docker.from_env()
    image = client.images.get(DOCKER_IMAGE)
    sha256_digest = image.attrs["RepoDigests"][0].split(":")[1]
    print("Found RepoDigest for latest docker image: " + sha256_digest)

    print("Publish evidence to ComplianceDB")
    evidence = {
        "evidence_type": "",
        "contents":
            {
                "is_compliant": False,
                "url": "",
                "description": ""
            }
    }
    evidence["evidence_type"] = os.getenv('EVIDENCE_TYPE', "EVIDENCE_TYPE_UNDEFINED")
    evidence["contents"]["description"] = "Added in build " + os.getenv('BUILD_TAG', "UNDEFINED")
    evidence["contents"]["url"] = os.getenv('URL', "URL_UNDEFINED")
    evidence["contents"]["is_compliant"] = os.getenv('IS_COMPLIANT', "FALSE") == "TRUE"

    with open(project_file) as project_file_contents:
        add_evidence(host, project_file_contents, sha256_digest, evidence)

if __name__ == '__main__':
    main()
