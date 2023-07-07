#!/usr/bin/env bash
set -euo pipefail
ME=$(basename $0)
WHEREAMI=$(dirname $0)
fail() { echo "${ME}: error: $*" >&2 ; exit 1 ; }
test -v KEEPDB || fail "missing KEEPDB environment variable"
test -d "$KEEPDB" || fail "missing KEEPDB directory '$KEEPDB'"
usage() {
    cat >&2 <<__eod__
usage: $ME [-q|--query] [-c|--common] <<<OID...
usage: $ME -a|--add LABEL... <<<OID...
usage: $ME -d|--drop LABEL... <<<OID...
__eod__
    exit 1
}
IS_ADD=false
IS_DROP=false
IS_COMMON=false
while test $# -ne 0 ; do
    case $1 in
        -q|--query) shift ;;
        -c|--common) shift ; IS_COMMON=true ;;
        -a|--add) shift ; IS_ADD=true ; break ;;
        -d|--drop) shift ; IS_DROP=true ; break ;;
        *) usage ;;
    esac
done
TMP_ARG_LABELS=''
if $IS_ADD || $IS_DROP ; then
    TMP_ARG_LABELS=$(mktemp -t "${ME}.XXXXXXXXXX")
    sed 's/  */\n/g' <<<$@ | sed '/^[[:blank:]]*$/d' | sort -u >$TMP_ARG_LABELS
else
    test $# -eq 0 || usage
fi
sed 's/  */\n/g' | \
while read OID ; do
    echo -n "$KEEPDB/spot/"
    tr '/' '\n' <<<$OID | sed '1s/./&\//g' | tr -d '\n'
    echo '.label'
done | {
    TMP_LABELS=$(mktemp -t "${ME}.XXXXXXXXXX")
    TMP_AUX=$(mktemp -t "${ME}.XXXXXXXXXX")
    IS_PRIMED=false
    while read LABEL_FILE ; do
        if $IS_ADD ; then
            sort --merge --uniq "$LABEL_FILE" $TMP_ARG_LABELS >$TMP_LABELS
            cp -f $TMP_LABELS "$LABEL_FILE"
        elif $IS_DROP ; then
            grep -F -x -v -f $TMP_ARG_LABELS "$LABEL_FILE" >$TMP_LABELS
            cp -f $TMP_LABELS "$LABEL_FILE"
        else
            $IS_PRIMED || { IS_PRIMED=true ; cat "$LABEL_FILE" >$TMP_LABELS ; continue ; }
            if $IS_COMMON ; then
                comm -12 $TMP_LABELS "$LABEL_FILE" >$TMP_AUX
            else
                sort --merge --uniq $TMP_LABELS "$LABEL_FILE" >$TMP_AUX
            fi
            cat $TMP_AUX >$TMP_LABELS
        fi
    done
    $IS_ADD || $IS_DROP || cat $TMP_LABELS
    rm -f $TMP_LABELS $TMP_AUX
}
test -z "$TMP_ARG_LABELS" || rm -f $TMP_ARG_LABELS
