#!/bin/sh

# A docker image entrypoint for gathering coverage data
set -e
pytest --ignore=integration_tests --capture=no --cov=src
coverage html
