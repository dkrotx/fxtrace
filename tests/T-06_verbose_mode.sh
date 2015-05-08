###############################################################################
## Being launched in verbose mode, fxtrace will print access-mode for files,
## not just filenames.
###############################################################################


. $( dirname $0 )/test.incl.sh

mkdir subdir
touch subdir/file.txt


catpath=$( getbinpath cat )
findpath=$( getbinpath find )

__TAB=$( echo -e "\t" )

# run as usual.
$__FXTRACE -v find subdir -name '*.txt' -exec cat {} \; >/dev/null
assert_file_contains fxtrace.log "x${__TAB}${findpath}" "x${__TAB}${catpath}" "r${__TAB}$( readlink -e subdir/file.txt )"

# run with restriction to execute
$__FXTRACE --mode=x --verbose find subdir -name '*.txt' -exec cat {} \; >/dev/null
assert_file_contains fxtrace.log "x${__TAB}${findpath}" "x${__TAB}${catpath}"
assert_file_not_contains fxtrace.log "r${__TAB}$( readlink -e subdir/file.txt )"

# now with restriction to read
$__FXTRACE --mode=r --verbose=1 find subdir -name '*.txt' -exec cat {} \; >/dev/null
assert_file_contains fxtrace.log "r${__TAB}$( readlink -e subdir/file.txt )"
assert_file_not_contains fxtrace.log "x${__TAB}${findpath}" "x${__TAB}${catpath}"
