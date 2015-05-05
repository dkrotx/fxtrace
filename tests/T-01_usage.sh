## test actuality of usage

. $( dirname $0 )/test.incl.sh

$__FXTRACE -l fxtrace.log cat /etc/passwd >/dev/null
assert_file_contains fxtrace.log "/bin/cat" "/etc/passwd"
