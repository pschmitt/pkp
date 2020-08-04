#!/usr/bin/env bash

cd "$(readlink -f "$(dirname "$0")")" || exit 9

docker run -it --rm \
  -v "$PWD:/app" \
  -e STATICX=1 \
  -e STATICX_ARGS="--strip" \
  pschmitt/pyinstaller:3.7 \
  pkp.py
