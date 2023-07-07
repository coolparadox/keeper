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
SPOT_DIR="$KEEPDB/spot"
sed 's/  */\n/g' | \
while read OID ; do
    tr '/' '\n' <<<$OID | sed '1s/./&\//g' | tr -d '\n'
    echo
done | while read OID_BASE ; do
    OID_BASE_SUBDIR=$(dirname "$OID_BASE")
    OID_SUBDIR="$SPOT_DIR/$OID_BASE_SUBDIR"
    find "$OID_SUBDIR" -maxdepth 1 -name $(basename "$OID_BASE"\*) -delete
    ( cd "$SPOT_DIR" && rmdir -p --ignore-fail-on-non-empty "$OID_BASE_SUBDIR" )
done
