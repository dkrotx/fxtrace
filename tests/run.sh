#!/usr/bin/env bash

set -e
set -o pipefail

err() {
    echo "Error:" "$@" >&2
    exit 1
}

clear_tmp() {
    [[ -n $TESTDIR ]] && rm -rf "$TESTDIR/tmp"
}

print_ok() {
    echo OK
}

print_failed() {
    if [[ -t 1 ]]; then
        echo -e '\033[1mFAILED\033[0m'
    else
        echo FAILED
    fi
}


TESTDIR=$( readlink -f $( dirname "$0" ) )
LIBDESCR=$TESTDIR/../libfxtrace.la
__FXTRACE=$TESTDIR/../src/fxtrace

[[ -s $LIBDESCR ]]  || err "$LIBDESCR not found. Did you compile sources?"
[[ -x $__FXTRACE ]] || err "$__FXTRACE not found or not executable"

FXTRACE_LIB_PATH=$( find "$TESTDIR/../" -name libfxtrace.so | head -n 1 )
[[ -n $FXTRACE_LIB_PATH ]] || err "libfxtrace.so not found. Did you compile sources?"

# Do not resolve last symlink.
# Since being launched after install, it will be used exactly this way
export FXTRACE_LIB_PATH=$( readlink -e $( dirname "$FXTRACE_LIB_PATH" ) )/libfxtrace.so

export __FXTRACE
cd $TESTDIR

trap clear_tmp EXIT

NTESTS=$( ls T-[0-9][0-9]*.sh | wc -l | awk '{ print $1 }' )
i=0
NFAILED=0

if [[ $NTESTS -eq 0 ]]; then
    echo "No tests found!" >&2
    exit 0
fi

for t in $( ls T-*.sh ); do
    printf "[%2d/%-2d] %-30s" $(( ++i )) $NTESTS $t

    rm -rf tmp && mkdir tmp
    ( cd tmp && bash "../$t" ) && print_ok || { print_failed; (( ++NFAILED )); }
done

echo "----------------------------------------"
echo "$[ $NTESTS - $NFAILED ] test(s) passed, $NFAILED failed"

[[ $NFAILED -eq 0 ]] || { echo FAIL; exit 1; }

echo SUCCESS
exit 0
