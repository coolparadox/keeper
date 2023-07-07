#!/usr/bin/env bash
set -euo pipefail
ME=$(basename $0)
fail() { echo "${ME}: error: $*" >&2 ; exit 1 ; }
test -v KEEPDB || fail "missing KEEPDB environment variable"
test -d "$KEEPDB" || fail "missing KEEPDB directory '$KEEPDB'"
usage() {
    cat >&2 <<__eod__
usage: $ME <<<LABEL_REGEX...
usage: $ME -l|--latest-acquired
__eod__
    exit 1
}
IS_STDIN=true
while test $# -ne 0 ; do
    case $1 in
        -l|--latest)
            shift
            test $# -eq 0 || usage
            IS_STDIN=false
            ;;
        *) usage ;;
    esac
done
LATEST_OIDS_FILE="$KEEPDB/latest_oids"
touch "$LATEST_OIDS_FILE"
$IS_STDIN || exec cat "$LATEST_OIDS_FILE"
TMP_PATTERNS=$(mktemp -t "${ME}.XXXXXXXXXX")
sed 's/  */\n/g' >$TMP_PATTERNS
cd "$KEEPDB/spot"
find -type f -name '*.label' | sed 's/^\.\///' | while read LABEL_FILE ; do
    grep -q -f $TMP_PATTERNS $LABEL_FILE || continue
    echo $LABEL_FILE
done | sed -r -e 's/\..*//' -e 's/\/([^\/]*)$/.\1/' -e 's/\///g' -e 's/\./\//'
rm -r $TMP_PATTERNS
