#!/usr/bin/env bash

###############################################################################
## Bug: if we run fxtrace with relative logfile and program performs cd(1)
## then it's subprocess will fail to write logfile
###############################################################################

set -e
. $( dirname $0 )/test.incl.sh

CAT_PATH=$( getbinpath cat )

mkdir subdir
touch subdir/file.txt

$__FXTRACE --log fxtrace.log bash -c "cd subdir && cat file.txt" >/dev/null
assert_file_contains fxtrace.log "$CAT_PATH" "file.txt"
