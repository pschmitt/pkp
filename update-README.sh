#!/usr/bin/env bash

cd "$(cd "$(dirname "$0")" >/dev/null 2>&1; pwd -P)" || exit 9

# shellcheck disable=1090
source "$(poetry env list --full-path | awk '{ print $1}')/bin/activate"

MARKER_START='<!-- PKP_HELP -->'
MARKER_STOP='<!-- PKP_HELP_END -->'

# Delete everything between markers
# https://stackoverflow.com/a/6287940
sed -i "/^${MARKER_START}/,/^${MARKER_STOP}/{/^${MARKER_START}/!{/^${MARKER_STOP}/!d}}" README.md

# shellcheck disable=2091
HELP="\`\`\`shell
$(python pkp.py --help 2>&1)
\`\`\`"

# FIXME Useless echo?
sed -i "/${MARKER_START}/r"<(echo "$HELP") README.md
