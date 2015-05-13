#!/usr/bin/env bash

###############################################################################
## Fxtrace should only logs files, not directories.
## It's usually not interesting to see plenty of them in access-log
###############################################################################

set -e
. $( dirname $0 )/test.incl.sh

CAT_PATH=$( getbinpath cat )
FIND_PATH=$( getbinpath find )

mkdir subdir
touch subdir/file.txt
mkdir subdir/onemoredir
touch subdir/onemoredir/file2.txt

# find(1) open directory to read it's content. Check where is no directories in logfile
$__FXTRACE find subdir -name '*.txt' -exec cat {} \; >/dev/null

assert_file_contains fxtrace.log "$CAT_PATH" "$FIND_PATH" "subdir/file.txt" "subdir/onemoredir/file2.txt"

# check there is no dirs
for f in $( cut -f 2- fxtrace.log ); do
    if [[ -d $f ]]; then
        err "directory ($f) found in log, but should not!"
    fi
done
