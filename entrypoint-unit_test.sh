#!/bin/sh

# A docker image entrypoint for running unit tests
set -e
rm -rf build/test
mkdir -p build/test
pytest -rA --capture=no --junit-xml=build/test/pytest_unit.xml
