#!/usr/bin/env bash
set -euo pipefail
ME=$(basename $0)
fail() { echo "${ME}: error: $*" >&2 ; exit 1 ; }
test -v KEEPDB || fail "missing KEEPDB environment variable"
test -d "$KEEPDB" || fail "missing KEEPDB directory '$KEEPDB'"
usage() { echo "usage: $ME <OID..."; exit 1; }
test $# -eq 0 || usage
sed 's/  */\n/g' | \
while read OID ; do
    echo -n "$KEEPDB/spot/"
    echo $OID | tr '/' '\n' | sed '1s/./&\//g' | tr -d '\n'
    echo
done | while read PREFIX ; do
    FILENAME=$(sed -e '/^filename:/!d' -e 's/^[^:]*://' "${PREFIX}.label")
    test -e "$FILENAME" && fail "filename '$FILENAME' already exists" || :
    gzip -cd "${PREFIX}.gz" >$FILENAME
done
