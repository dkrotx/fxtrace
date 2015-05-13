set -e
set -o pipefail

TMP_TEST_DIR=

PrintCallStack()
{
  echo "Call Stack: "
  for ((i = 0; i < ${#FUNCNAME[@]}; i++))
  do
        if [[ $i -eq 0 ]]; then
          local lineno=$LINENO
        else
          local lineno=${BASH_LINENO[ $(($i - 1)) ]}
        fi
        echo "  [$i] ${BASH_SOURCE[$i]}:$lineno (${FUNCNAME[$i]})"
  done
}

err() {
    echo "Error: " "$@" >&2
    PrintCallStack >&2
    exit 1
}

assert_file_contains() {
    local file=$1
    shift

    [[ -e $file ]] || err "$file not found"

    while [[ $# -gt 0 ]]; do
        grep -q "$1" "$file" || err "string \"$1\" not found in file $file"
        shift
    done
}

assert_file_not_contains() {
    local file=$1
    shift

    [[ -e $file ]] || err "$file not found"

    while [[ $# -gt 0 ]]; do
        grep -q "$1" "$file" && err "string \"$1\" found in file $file, but should not" || true
        shift
    done
}

assert_files_equal() {
    [[ $# -eq 2 ]] || err "assert_files_equal: bad invocation"
    diff -U2 $1 $2 || err "files $1 and $2 not equal"
}

getbinpath() {
    # some modern distributions doesn't have which(1). type, instead, requred by POSIX
    { type -P $1 || which $1; } 2>&1
}


clear_tmp() {
    [[ -n $TMP_TEST_DIR ]] && cd "$STARTDIR" && rm -rf "$TMP_TEST_DIR"
}

STARTDIR=$( readlink -f $PWD )

if [[ $INSTALLCHECK = "yes" ]]; then
    __FXTRACE=$AUTOTEST_PATH/fxtrace
    [[ -x $__FXTRACE ]] || err "$__FXTRACE not found or not executable. Do you performed make install?"

    echo "checking in installation mode (fxtrace=$__FXTRACE)" >&2
else
    __FXTRACE=$( readlink -e ./src/fxtrace )
    [[ -x $__FXTRACE ]] || err "$__FXTRACE not found or not executable. Do you performed make?"

    FXTRACE_LIB_PATH=$( find . -name libfxtrace.so | head -n 1 )
    [[ -n $FXTRACE_LIB_PATH ]] || err "libfxtrace.so not found. Did you compile sources?"

    # Do not resolve last symlink.
    # Since being launched after install, it will be used exactly this way
    export FXTRACE_LIB_PATH=$( readlink -e $( dirname "$FXTRACE_LIB_PATH" ) )/libfxtrace.so

    echo "checking in compiled mode (fxtrace=$__FXTRACE, FXTRACE_LIB_PATH=$FXTRACE_LIB_PATH)" >&2
fi


TMP_TEST_DIR=$( readlink -e "$( mktemp -d fxtrace-test.tmp.XXXXXX )" )
[[ -n $TMP_TEST_DIR ]] || err "Error creating temp dir"
trap clear_tmp EXIT
cd $TMP_TEST_DIR
