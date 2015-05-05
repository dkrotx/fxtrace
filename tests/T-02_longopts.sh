###############################################################################
## test long options syntax works well
###############################################################################

. $( dirname $0 )/test.incl.sh

## restrict path and mode using longopts
$__FXTRACE --log fxtrace.log --prefix /bin --mode x cat /etc/passwd >/dev/null || err "long options should work"
assert_file_contains fxtrace.log "/bin/cat"
assert_file_not_contains fxtrace.log "/etc/passwd"

## same as above, but use longopts in GNU way: not "--opt value", but "--opt=value"
$__FXTRACE --log=fxtrace.log --prefix=/bin --mode=x cat /etc/passwd >/dev/null || err "GNU long options should work"
assert_file_contains fxtrace.log "/bin/cat"
assert_file_not_contains fxtrace.log "/etc/passwd"
cp fxtrace.log fxtrace.log.longopts


## check what --opt="value" and --opt='value' works too
rm -f fxtrace.log
$__FXTRACE --log="fxtrace.log" --prefix='/bin' --mode=x cat /etc/passwd >/dev/null || err "GNU long options with quotes should work"
assert_files_equal fxtrace.log.longopts fxtrace.log

## mixed variant may look strange, but should work too
$__FXTRACE --log=fxtrace.log --prefix /bin --mode=x cat /etc/passwd >/dev/null || err "mixed long options should work"
assert_files_equal fxtrace.log.longopts fxtrace.log
