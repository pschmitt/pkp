#!/usr/bin/env bash

BUILD_IMAGE=pschmitt/pyinstaller:3.8
MANIFEST= # $(cat ./MANIFEST.cache)

usage() {
  echo "Usage: $(basename "$0") ARCH"
}

is_termux() {
  command -v termux-info >/dev/null
}

get_build_image_manifest() {
  # Cache manifest
  if [[ -z "$MANIFEST" ]]
  then
    MANIFEST="$(docker manifest inspect "$BUILD_IMAGE")"
  fi

  echo "$MANIFEST"
}

get_build_image_archs() {
  get_build_image_manifest | \
    jq -r '.manifests[].platform.architecture' | \
    sort -u
}

get_build_image_digest() {
  local arch="${1:-amd64}"

  get_build_image_manifest | \
    jq -r '.manifests[] | select(.platform.architecture == "'"${arch}"'").digest'
}

build() {
  if is_termux
  then
    build_termux
    return
  fi

  local arch="${1:-amd64}"
  local digest
  digest="$(get_build_image_digest "$arch")"

  if [[ -z "$digest" ]]
  then
    echo "Unable to find digest for $arch." >&2
    return 1
  fi

  echo "👷 Starting build of pkp (${arch})"

  cd "$(readlink -f "$(dirname "$0")")" || exit 9
  docker run --rm \
    -v "$PWD:/app" \
    -e STATICX=1 \
    -e STATICX_ARGS="--strip" \
    -e STATICX_OUTPUT="./dist/pkp-${arch}-static" \
    "pschmitt/pyinstaller@${digest}" \
    -n "pkp-${arch}" pkp.py
}

build_termux() {
  if ! is_termux
  then
    echo "This script requires to be run from within Termux." >&2
    exit 2
  fi

  echo "👷 Setting up build environment for Termux"

  cd "$(cd "$(dirname "$0")" >/dev/null 2>&1; pwd -P)" || exit 9

  rm -rf ./venv ./dist ./build ./__pycache__
  python -m venv venv
  # shellcheck disable=1091
  source ./venv/bin/activate
  pip install -U pip wheel
  pip install -r requirements.txt
  pip install -r requirements-dev.txt

  local arch
  arch="$(uname -m)"

  case "$arch" in
    aarch64)
      arch=arm64
      ;;
    arm*)
      arch=arm
      ;;
  esac

  echo "👷 Starting build of pkp (${arch}-termux)"

  LD_LIBRARY_PATH="${PREFIX}/lib" \
    pyinstaller -F -n "pkp-${arch}-termux" ./pkp.py
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  case "$1" in
    help|h|-h|--help)
      usage
      exit 0
      ;;
    all|--all|-a|-A)
      BUILD_ALL=1
      ;;
    termux|android)
      BUILD_TERMUX=1
      ;;
  esac

  if [[ -n "$BUILD_ALL" ]]
  then
    for arch in $(get_build_image_archs)
    do
      build "$arch"
    done
  elif [[ -n "$BUILD_TERMUX" ]]
  then
    build_termux
  else
    build "$@"
  fi
fi
