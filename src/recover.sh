#!/usr/bin/env bash
set -euo pipefail
ME=$(basename $0)
fail() { echo "${ME}: error: $*" >&2 ; exit 1 ; }
test -v KEEPDB || fail "missing KEEPDB environment variable"
test -d "$KEEPDB" || fail "missing KEEPDB directory '$KEEPDB'"
usage() { echo "usage: $ME [-f|--force] [-v|--verbose] <OID..."; exit 1; }
IS_FORCE=false
IS_QUIET=true
while test $# -ne 0 ; do
    case $1 in
        -f|--force) shift ; IS_FORCE=true ;;
        -v|--verbose) shift ; IS_QUIET=false ;;
        *) usage ;;
    esac
done
test $# -eq 0 || usage
sed 's/  */\n/g' | \
while read OID ; do
    echo -n "$KEEPDB/spot/"
    echo $OID | tr '/' '\n' | sed '1s/./&\//g' | tr -d '\n'
    echo
done | while read PREFIX ; do
    LABEL_FILE="${PREFIX}.label"
    FILENAME=$(sed -e '/^filename:/!d' -e 's/^[^:]*://' "$LABEL_FILE")
    test -n "$FILENAME" || fail "missing 'filename:...' in $(basename $LABEL_FILE)"
    $IS_FORCE || { test -e "$FILENAME" && fail "filename '$FILENAME' already exists" || : ; }
    $IS_QUIET || echo -n $(basename "$PREFIX")\ --\>\  >&2
    gzip -cd "${PREFIX}.gz" >$FILENAME
    $IS_QUIET || echo $FILENAME >&2
done
