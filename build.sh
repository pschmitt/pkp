#!/usr/bin/env bash

BUILD_IMAGE=pschmitt/pyinstaller:3.9
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

get_build_image_manifest_for_arch() {
  local arch="${1:-amd64}"

  get_build_image_manifest | \
    jq -r '.manifests[] | select(.platform.architecture == "'"${arch}"'")'
}

get_build_image_archs() {
  get_build_image_manifest | \
    jq -r '.manifests[].platform.architecture' | \
    sort -u
}

get_build_image_digest() {
  get_build_image_manifest_for_arch "$1" | \
    jq -r '.digest'
}

get_build_image_platform_name() {
  get_build_image_manifest_for_arch "$1" | \
    jq -r '.platform | .os + "/" + .architecture +
      (if (.variant != null) then ("/" + .variant) else "" end)'
}

build() {
  if is_termux
  then
    build_termux
    return "$?"
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

  local extra_args=()
  if [[ "$arch" == arm ]]
  then
    # DIRTYFIX for https://github.com/docker/buildx/issues/395
    # Upstream issue https://github.com/pyca/cryptography/issues/5771
    extra_args+=(-e CRYPTOGRAPHY_DONT_BUILD_RUST=1)
  fi

  # Get the actual platform name (eg: linux/arm/v7) of the target image to
  # silence the following warning:
  # WARNING: The requested image's platform (linux/arm/v7) does not
  # match the detected host platform (linux/amd64) and no specific
  # platform was requested
  local platform
  platform="$(get_build_image_platform_name "$arch")"

  docker run --rm --platform "$platform" \
    -v "$PWD:/app" \
    -e STATICX=1 \
    -e STATICX_ARGS="--strip" \
    -e STATICX_OUTPUT="./dist/pkp-${arch}-static" \
    "${extra_args[@]}" \
    "pschmitt/pyinstaller@${digest}" \
    -n "pkp-${arch}" pkp.py
}

build_termux() {
  if ! is_termux
  then
    echo "This script requires to be run from within Termux." >&2
    return 2
  fi

  echo "👷 Setting up build environment for Termux"

  cd "$(cd "$(dirname "$0")" >/dev/null 2>&1; pwd -P)" || exit 9

  rm -rf ./venv ./dist ./build ./__pycache__
  python -m venv venv
  # shellcheck disable=1091
  source ./venv/bin/activate
  pip install -U pip wheel
  pip install -r .

  local version
  version="$(python -c "import pkp; print(pkp.__version__)")"

  if [[ -z "$version" ]]
  then
    echo "Failed to determine current version" >&2
    return 7
  fi

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

  local pkp_bin="pkp-${version}-${arch}-termux"
  echo "👷 Starting build of pkp (${arch}-termux)"

  LD_LIBRARY_PATH="${PREFIX}/lib" \
    pyinstaller -F -n "$pkp_bin" ./pkp.py

  local destdir=${DEST:-/sdcard/Download}
  echo "👷 Moving binary file to ${destdir}"
  mv "./dist/${pkp_bin}" "$destdir"
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
