#!/bin/sh

# A docker image entrypoint for gathering security data
set -e
rm -rf build/security || true
mkdir -p build/security
bandit --recursive src --format xml --output build/security/security.xml
