#!/usr/bin/env bash
set -euo pipefail
ME=$(basename $0)
fail() { echo "${ME}: error: $*" >&2 ; exit 1 ; }
test -v KEEPDB || fail "missing KEEPDB environment variable"
test -d "$KEEPDB" || fail "missing KEEPDB directory '$KEEPDB'"
usage() { echo "usage: $ME SRC_FILE" >&2; exit 1; }
test $# -eq 1 || usage
ACQ_PATH=$1
ACQ_SIZE=$(stat --printf='%s' "$ACQ_PATH")
SPOTS_DIR="$KEEPDB/spot"
SPOT_SIZE_SUBDIR=$(echo "obase=16;$ACQ_SIZE" | bc | sed 's/\(..\)/\\\\x\1/g' | xargs printf | base64 -w0 | sed 's/\//_/g' | rev | sed -e 's/./\/&/g' -e 's/\///')
SPOT_BASE_NAME=$(cksum -a sha1 --untagged -b --debug "$ACQ_PATH" | sed -e 's/ .*//' -e 's/\//_/g')
SPOT_DIR="$SPOTS_DIR/$SPOT_SIZE_SUBDIR"
SPOT_BASE_PATH="$SPOT_DIR/${SPOT_BASE_NAME}"
BLOB_PATH="${SPOT_BASE_PATH}.gz"
echo ${SPOT_SIZE_SUBDIR//\//}/$SPOT_BASE_NAME
if test -e "$BLOB_PATH" ; then
    gzip -dc "$BLOB_PATH" | cmp -s "$ACQ_PATH" - || fail "the 'impossible' happened!"
    fail "already acquired"
else
    mkdir -p "$SPOT_DIR"
    BLOB_PATH_TMP="${BLOB_PATH}.tmp"
    gzip -9nc <"$ACQ_PATH" >"${BLOB_PATH_TMP}"
    mv -f "${BLOB_PATH_TMP}" "$BLOB_PATH"
fi
LABEL_PATH="${SPOT_BASE_PATH}.label"
touch "$LABEL_PATH"
LABEL_PATH_TMP="${LABEL_PATH}.tmp"
MODIFIED_EPOCH=$(stat --printf='%Y' $ACQ_PATH)
sort -u "$LABEL_PATH" - >"$LABEL_PATH_TMP" <<__eod__
acquired:$(date -u +%F)
filename:$(basename "$ACQ_PATH")
mimetype:$(file --brief --mime-type $ACQ_PATH)
modified:$(date -ud "@$MODIFIED_EPOCH" +%F)
__eod__
mv -f "$LABEL_PATH_TMP" "$LABEL_PATH"
