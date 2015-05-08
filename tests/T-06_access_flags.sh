###############################################################################
## fxtrace print access-mode for files. Check they are correct
###############################################################################

. $( dirname $0 )/test.incl.sh

mkdir subdir
touch subdir/file.txt


catpath=$( getbinpath cat )
findpath=$( getbinpath find )

__TAB=$( echo -e "\t" )

# run as usual.
$__FXTRACE find subdir -name '*.txt' -exec cat {} \; >/dev/null
assert_file_contains fxtrace.log "x${__TAB}${findpath}" "x${__TAB}${catpath}" "r${__TAB}$( readlink -e subdir/file.txt )"

# run with restriction to execute
$__FXTRACE --mode=x find subdir -name '*.txt' -exec cat {} \; >/dev/null
assert_file_contains fxtrace.log "x${__TAB}${findpath}" "x${__TAB}${catpath}"
assert_file_not_contains fxtrace.log "r${__TAB}$( readlink -e subdir/file.txt )"

# now with restriction to read
$__FXTRACE --mode=r find subdir -name '*.txt' -exec cat {} \; >/dev/null
assert_file_contains fxtrace.log "r${__TAB}$( readlink -e subdir/file.txt )"
assert_file_not_contains fxtrace.log "x${__TAB}${findpath}" "x${__TAB}${catpath}"
