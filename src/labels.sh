#!/usr/bin/env bash
set -euo pipefail
ME=$(basename $0)
WHEREAMI=$(dirname $0)
fail() { echo "${ME}: error: $*" >&2 ; exit 1 ; }
test -v KEEPDB || fail "missing KEEPDB environment variable"
test -d "$KEEPDB" || fail "missing KEEPDB directory '$KEEPDB'"
usage() { echo "usage: $ME [-c|--common]"; exit 1; }
IS_COMMON=false
while test $# -ne 0 ; do
    case $1 in
        -c|--common) shift ; IS_COMMON=true ;;
        *) usage ;;
    esac
done
test $# -eq 0 || usage
sed 's/  */\n/g' | \
while read OID ; do
    echo -n "$KEEPDB/spot/"
    echo $OID | tr '/' '\n' | sed '1s/./&\//g' | tr -d '\n'
    echo '.label'
done | {
    TMP_LABELS=$(mktemp -t "${ME}.XXXXXXXXXX")
    TMP_AUX=$(mktemp -t "${ME}.XXXXXXXXXX")
    IS_PRIMED=false
    while read LABEL_FILE ; do
        $IS_PRIMED || { IS_PRIMED=true ; cat $LABEL_FILE >$TMP_LABELS ; continue ; }
        if $IS_COMMON ; then
            comm -12 $TMP_LABELS $LABEL_FILE >$TMP_AUX
        else
            sort --merge --uniq $TMP_LABELS $LABEL_FILE >$TMP_AUX
        fi
        cat $TMP_AUX >$TMP_LABELS
    done
    cat $TMP_LABELS
    rm -f $TMP_AUX $TMP_LABELS
}
