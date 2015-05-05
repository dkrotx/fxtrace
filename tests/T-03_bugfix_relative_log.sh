###############################################################################
## Bug: if we run fxtrace with relative logfile and program performs cd(1)
## then it's subprocess will fail to write logfile
###############################################################################

. $( dirname $0 )/test.incl.sh

mkdir subdir
touch subdir/file.txt

$__FXTRACE --log fxtrace.log bash -c "cd subdir && cat file.txt" >/dev/null
assert_file_contains fxtrace.log "/bin/cat" "file.txt"
