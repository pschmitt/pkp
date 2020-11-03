#!/usr/bin/env bash

cd "$(cd "$(dirname "$0")" >/dev/null 2>&1; pwd -P)" || exit 9

poetry export -f requirements.txt -o requirements.txt --without-hashes
poetry export -f requirements.txt --dev -o requirements-dev.txt --without-hashes
