#!/usr/bin/env bash
set -euo pipefail
ME=$(basename $0)
fail() { echo "${ME}: error: $*" >&2 ; exit 1 ; }
test -v KEEPDB || fail "missing KEEPDB environment variable"
test -d "$KEEPDB" || fail "missing KEEPDB directory '$KEEPDB'"
usage() { echo "usage: $ME [-C|--dir DIR] [-f|--force] [-s|--skip] <<<OID..."; exit 1; }
IS_FORCE=false
IS_SKIP=false
RECOVER_DIR=$PWD
while test $# -ne 0 ; do
    case $1 in
        -C|--dir) shift ; test $# -ne 0 || usage ; RECOVER_DIR=$1 ; shift ;;
        -f|--force) shift ; IS_FORCE=true ;;
        -s|--skip) shift ; IS_SKIP=true ;;
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
    FILENAME=$(sed -e '/^filename:/!d' -e 's/^[^:]*://' -e 'q' "$LABEL_FILE")
    test -n "$FILENAME" || fail "missing 'filename:...' label in $OID"
    test ! -e "$FILENAME" || {
        if $IS_SKIP ; then
            echo "${ME}: info: skipping '$FILENAME' in '$RECOVER_DIR' due to ${OID}: file exists" >&2
            continue
        elif $IS_FORCE ; then
            echo "${ME}: warning: overwriting '$FILENAME' in '$RECOVER_DIR' due to ${OID}" >&2
        else
            fail "filename '$FILENAME' already exists in '$RECOVER_DIR' -- ${OID}"
        fi
    }
    gzip -cd "${PREFIX}.gz" >"$FILENAME"
done
