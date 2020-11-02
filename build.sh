#!/usr/bin/env bash

BUILD_IMAGE=pschmitt/pyinstaller:3.8
MANIFEST= # $(cat ./MANIFEST.cache)

usage() {
  echo "Usage: $(basename "$0") ARCH"
}

get_build_image_manifest() {
  local arch="${1:-amd64}"

  # Cache manifest
  if [[ -z "$MANIFEST" ]]
  then
    MANIFEST="$(docker manifest inspect "$BUILD_IMAGE")"
  fi

  jq -r '.manifests[] | select(.platform.architecture == "'"${arch}"'").digest' <<< "$MANIFEST"
}

build() {
  local arch="${1:-amd64}"
  local digest
  digest="$(get_build_image_manifest "$arch")"

  if [[ -z "$digest" ]]
  then
    echo "Unable to find digest for $arch." >&2
    return 1
  fi

  cd "$(readlink -f "$(dirname "$0")")" || exit 9
  docker run --rm \
    -v "$PWD:/app" \
    -e STATICX=1 \
    -e STATICX_ARGS="--strip" \
    -e STATICX_OUTPUT="./dist/pkp_${arch}_static" \
    "pschmitt/pyinstaller@${digest}" \
    pkp.py
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  case "$1" in
    help|h|-h|--help)
      usage
      exit 0
      ;;
  esac

  build "$@"
fi
