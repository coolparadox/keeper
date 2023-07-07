#!/usr/bin/env bash
set -euo pipefail
ME=$(basename $0)
WHEREAMI=$(dirname $0)
fail() { echo "${ME}: error: $*" >&2 ; exit 1 ; }
test -v KEEPDB || fail "missing KEEPDB environment variable"
test -d "$KEEPDB" || fail "missing KEEPDB directory '$KEEPDB'"
usage() {
    cat >&2 <<__eod__
usage: $ME <<<OID...
__eod__
    exit 1
}
test $# -eq 0 || usage
sed 's/  */\n/g' | \
while read OID ; do
    echo -n "$KEEPDB/spot/"
    tr '/' '\n' <<<$OID | sed '1s/./&\//g' | tr -d '\n'
    echo
done | while read PREFIX ; do
    PREFIX_DIR=$(dirname "$PREFIX")
    find "$PREFIX_DIR" -maxdepth 1 -name $(basename "$PREFIX"\*) -delete
    rmdir -p --ignore-fail-on-non-empty "$PREFIX_DIR"
done
