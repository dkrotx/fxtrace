###############################################################################
## Fxtrace should only logs files, not directories.
## It's usually not interesting to see plenty of them in access-log
###############################################################################


. $( dirname $0 )/test.incl.sh

mkdir subdir
touch subdir/file.txt
mkdir subdir/onemoredir
touch subdir/onemoredir/file2.txt


# find(1) open directory to read it's content. Check where is no directories in logfile
$__FXTRACE find subdir -name '*.txt' -exec cat {} \; >/dev/null

catpath=$( getbinpath cat )
findpath=$( getbinpath find )
assert_file_contains fxtrace.log "$catpath" "$findpath" "subdir/file.txt" "subdir/onemoredir/file2.txt"

# check there is no dirs
for f in $( cut -f 2- fxtrace.log ); do
    [[ -e $f ]] || err "file $f logged, but doesn't exists"
    if [[ -d $f ]]; then
        err "directory ($f) found in log, but should not!"
    fi
done
