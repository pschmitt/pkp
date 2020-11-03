#!/usr/bin/env bash

cd "$(cd "$(dirname "$0")" >/dev/null 2>&1; pwd -P)" || exit 9

poetry export -f requirements.txt --without-hashes -o requirements.txt
poetry export -f requirements.txt --without-hashes --dev -o requirements-dev.txt
