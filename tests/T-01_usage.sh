#!/usr/bin/env bash

###############################################################################
## test actuality of usage
###############################################################################

set -e
. $( dirname $0 )/test.incl.sh

CAT_PATH=$( getbinpath cat )
GREP_PATH=$( getbinpath grep )

## most basic usage
$__FXTRACE cat /etc/passwd >/dev/null
assert_file_contains fxtrace.log "/bin/cat" "/etc/passwd"
mv fxtrace.log fxtrace.log.orig

## same as above, but pass another logfile. Result should be the same
$__FXTRACE --log fxtracelog_special.txt cat /etc/passwd >/dev/null
assert_files_equal fxtrace.log.orig fxtracelog_special.txt

## check end-of-options works well
$__FXTRACE -l fxtrace.log -- cat /etc/passwd >/dev/null || err "end of options not recognized?"
assert_file_contains fxtrace.log "$CAT_PATH" "/etc/passwd"

## check logfile clears at next invocation
echo haha >test.txt
$__FXTRACE -l fxtrace.log grep -q haha test.txt >/dev/null
assert_file_not_contains fxtrace.log "$CAT_PATH" "/etc/passwd"
assert_file_contains fxtrace.log "$GREP_PATH" "test.txt"

## now restrict modes
$__FXTRACE -l fxtrace.log -m r cat /etc/passwd >/dev/null
assert_file_contains fxtrace.log "/etc/passwd"
assert_file_not_contains fxtrace.log "$CAT_PATH"

## now restrict path, so only /bin should be logged
$__FXTRACE -l fxtrace.log -p /bin cat /etc/passwd >/dev/null
assert_file_contains fxtrace.log "$CAT_PATH"
assert_file_not_contains fxtrace.log "/etc/passwd"

## now restrict both. Nothing should be logged
$__FXTRACE -l fxtrace.log -m r -p /bin cat /etc/passwd >/dev/null
assert_file_not_contains fxtrace.log "$CAT_PATH"
assert_file_not_contains fxtrace.log "/etc/passwd"
