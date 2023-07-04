#!/usr/bin/env bash
set -euo pipefail
ME=$(basename $0)
fail() { echo "${ME}: error: $*" >&2 ; exit 1 ; }
test -v KEEPDB || fail "missing KEEPDB environment variable"
test -d "$KEEPDB" || fail "missing KEEPDB directory '$KEEPDB'"
usage() { echo "usage: $ME"; exit 1; }
test $# -eq 0 || usage
cd "$KEEPDB/spot"
find -type f -name '*.gz' | \
sed -r -e 's/^\.*//' -e 's/\..*//' -e 's/\/([^\/]*)$/.\1/' -e 's/\///g' -e 's/\./\//'
