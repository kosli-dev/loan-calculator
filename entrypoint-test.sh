#!/bin/sh

# A docker image entrypoint for running tests
set -e
rm -rf build/test
mkdir -p build/test
pytest -rA --ignore=integration_tests --capture=no --junit-xml=build/test/pytest_unit.xml
