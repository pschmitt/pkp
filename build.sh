#!/usr/bin/env bash

BUILD_IMAGE=pschmitt/pyinstaller:3.8
MANIFEST= # $(cat ./MANIFEST.cache)

usage() {
  echo "Usage: $(basename "$0") ARCH"
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
    -e STATICX_OUTPUT="./dist/pkp_${arch}_static" \
    "pschmitt/pyinstaller@${digest}" \
    -n "pkp_${arch}" pkp.py
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
  esac

  if [[ -n "$BUILD_ALL" ]]
  then
    for arch in $(get_build_image_archs)
    do
      build "$arch"
    done
  else
    build "$@"
  fi
fi
