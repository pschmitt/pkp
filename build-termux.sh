#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  if ! command -v termux-info >/dev/null
  then
    echo "This script requires to be run from within Termux." >&2
    exit 2
  fi

  cd "$(cd "$(dirname "$0")" >/dev/null 2>&1; pwd -P)" || exit 9

  rm -rf ./venv ./dist ./build ./__pycache__
  python -m venv venv
  source ./venv/bin/activate
  pip install -U pip wheel
  pip install -r requirements.txt
  pip install -r requirements-dev.txt

  case "$(uname -m)" in
    aarch64)
      arch=arm64
      ;;
    arm*)
      arch=arm
      ;;
    *)
      arch="$(uname -m)"
      ;;
  esac

  LD_LIBRARY_PATH="${PREFIX}/lib" \
    pyinstaller -F -n "pkp_${arch}_termux" ./pkp.py
fi
