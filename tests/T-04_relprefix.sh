#!/usr/bin/env bash

###############################################################################
## relative path in --prefix is intuitive, hence should be supported
###############################################################################

set -e
. $( dirname $0 )/test.incl.sh

CAT_PATH=$( getbinpath cat )

mkdir subdir
touch subdir/file.txt

$__FXTRACE --prefix . --log fxtrace.log cat subdir/file.txt >/dev/null
assert_file_contains fxtrace.log "subdir/file.txt"
assert_file_not_contains fxtrace.log "$CAT_PATH" 
mv fxtrace.log fxtrace.log.orig

## same as above, but give prefix exactly
$__FXTRACE --prefix subdir --log fxtrace.log cat subdir/file.txt >/dev/null
assert_files_equal fxtrace.log.orig fxtrace.log

## same as above, but give explicitly as directory
$__FXTRACE --prefix subdir/ --log fxtrace.log cat subdir/file.txt >/dev/null
assert_files_equal fxtrace.log.orig fxtrace.log

## it's fine when prefix exists, but what with prefix which is really not a directory ?
$__FXTRACE --prefix subd --log fxtrace.log cat subdir/file.txt >/dev/null
assert_files_equal fxtrace.log.orig fxtrace.log
