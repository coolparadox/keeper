#!/usr/bin/env bash
set -euo pipefail
ME=$(basename $0)
fail() { echo "${ME}: error: $*" >&2 ; exit 1 ; }
test -v KEEPDB || fail "missing KEEPDB environment variable"
test -d "$KEEPDB" || fail "missing KEEPDB directory '$KEEPDB'"
usage() { echo "usage: $ME [-C|--dir DIR] [-f|--force] <OID..."; exit 1; }
IS_FORCE=false
RECOVER_DIR=$PWD
while test $# -ne 0 ; do
    case $1 in
        -C|--dir) shift ; test $# -ne 0 || usage ; RECOVER_DIR=$1 ; shift ;;
        -f|--force) shift ; IS_FORCE=true ;;
        *) usage ;;
    esac
done
test $# -eq 0 || usage
sed 's/  */\n/g' | \
while read OID ; do
    echo -n $OID
    echo -n " $KEEPDB/spot/"
    echo $OID | tr '/' '\n' | sed '1s/./&\//g' | tr -d '\n'
    echo
done | while read OID PREFIX ; do
    cd "$RECOVER_DIR"
    LABEL_FILE="${PREFIX}.label"
    FILENAME=$(sed -e '/^filename:/!d' -e 's/^[^:]*://' "$LABEL_FILE")
    test -n "$FILENAME" || fail "missing 'filename:...' label in $OID"
    test ! -e "$FILENAME" || {
        $IS_FORCE || fail "filename '$FILENAME' already exists in '$RECOVER_DIR' -- ${OID}"
        echo "${ME}: warning: overwriting '$FILENAME' in '$RECOVER_DIR' due to ${OID}" >&2
    }
    gzip -cd "${PREFIX}.gz" >$FILENAME
done
