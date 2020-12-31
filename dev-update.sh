#!/usr/bin/env bash

usage() {
  echo "Usage: $(basename "$0") readme|version"
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

  help_md="\`\`\`
${usage_str}
\`\`\`"

  # FIXME Useless echo?
  sed -i "/${marker_start}/r"<(echo "$help_md") README.md
}

version_compare() {
  local v1="$1"
  local v2="$2"
  local vmax

  vmax=$(echo -e "${v1}\n${v2}" | sort --version-sort | tail -1)

  [[ "$v2" == "$vmax" ]]
}

update_version() {
  if [[ -z "$1" ]]
  then
    echo "Missing version." >&2
    return 2
  fi

  local new_version="$1"

  cd "$(cd "$(dirname "$0")" >/dev/null 2>&1; pwd -P)" || exit 9

  local current_version
  current_version="$(poetry version -s --no-ansi)"

  if [[ "$new_version" == "bump" ]]
  then
    # shellcheck disable=2016
    new_version="$(sed -r 's/(.+\.)([0-9]+)/echo \1$((\2 + 1))/e' <<< "$current_version")"

    if [[ -z "$new_version" ]]
    then
      echo "Failed to bump version." >&2
      return 7
    fi
  fi

  if [[ "$current_version" == "$new_version" ]]
  then
    echo "We are already on version $new_version" >&2
    return 3
  fi

  if [[ -z "$DOWNGRADE" ]]
  then
    if ! version_compare "$current_version" "$new_version"
    then
      echo "Downgrades are not supported. $current_version > $new_version" >&2
      return 4
    fi
  fi

  echo "🆙 New version: $new_version" >&2

  sed -i -r 's/^(version\s?=\s?)".+"/\1"'"${new_version}"'"/' pyproject.toml
  sed -i -r 's/^(__version__\s?=\s?)".+"/\1"'"${new_version}"'"/' pkp.py

  git add pyproject.toml pkp.py
  if git commit -m "Version $new_version" -e
  then
    git tag -s "$new_version" -m "$new_version"
    git push --follow-tags

    poetry publish --build
  fi
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
    readme|md|README|README.md)
      update_readme
      ;;
    version|ver)
      shift
      DOWNGRADE="${DOWNGRADE:-}"
      update_version "$1"
      ;;
    *)
      usage
      exit 2
      ;;
  esac
fi
