#!/bin/sh

# A docker image entrypoint for gathering coverage data
set -e
rm -rf build/test
mkdir -p build/test
pytest -rA --ignore=integration_tests --capture=no --cov=src --junit-xml=build/test/pytest_unit.xml
coverage html -d build/coverage
