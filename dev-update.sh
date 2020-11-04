#!/usr/bin/env bash

usage() {
  echo "Usage: $(basename "$0") requirements|readme"
}

update_requirements() {
  cd "$(cd "$(dirname "$0")" >/dev/null 2>&1; pwd -P)" || exit 9

  poetry export -f requirements.txt --without-hashes -o requirements.txt
  poetry export -f requirements.txt --without-hashes --dev -o requirements-dev.txt
}

update_readme() {
  cd "$(cd "$(dirname "$0")" >/dev/null 2>&1; pwd -P)" || exit 9

  local marker_start='<!-- PKP_HELP -->'
  local marker_stop='<!-- PKP_HELP_END -->'
  local help_md
  local usage_str

  usage_str="$(poetry run python pkp.py --help 2>&1)"

  # shellcheck disable=2181
  if [[ "$?" -ne 0 ]] || [[ -z "$usage_str" ]]
  then
    echo "Failed to retrieve the output of pkp --help" >&2
    return 1
  fi

  # Delete everything between markers
  # https://stackoverflow.com/a/6287940
  sed -i "/^${marker_start}/,/^${marker_stop}/{/^${marker_start}/!{/^${marker_stop}/!d}}" README.md

  help_md="\`\`\`shell
${usage_str}
\`\`\`"

  # FIXME Useless echo?
  sed -i "/${marker_start}/r"<(echo "$help_md") README.md
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  set -euo pipefail

  if [[ "$#" -lt 1 ]]
  then
    usage >&2
    exit 2
  fi

  case "$1" in
    help|h|-h|--help)
      usage
      exit 0
      ;;
    requirements|req)
      update_requirements
      ;;
    readme|md|README|README.md)
      update_readme
      ;;
    *)
      usage
      exit 2
      ;;
  esac
fi
