#!/bin/bash

set -e
set -o pipefail

FXTRACE_LIB_PATH=@FXTRACE_SO_DIR@/libfxtrace.so

usage() {
    if [[ -n $1 ]]; then
        echo "$0: wrong usage: " "$@"
    fi

    local progname=$( basename $0 )

    cat - >&2 <<ENDUSAGE
Usage: $progname {-l logfile} [-m mode] [-p prefix] [-d] cmd [...]

Options:
  -l|--log:    trace operations to specified file (required)
  -m|--mode:   trace only specified operations. They are:
                 r - open for read
                 w - open for write
                 x - execute
                 s - stat(2)
 
  -p|--prefix: log only files which fullpath starts with given prefix
  -d|--debug:  print each event to stderr

EXAMPLES:

- Simple case:
  $ $progname --log /tmp/fxtrace.txt cat /etc/fstab

- More advanced case:
  $ $progname --log /tmp/fxtrace.txt --mode wsr --prefix \$HOME mc

ENDUSAGE
    exit ${USAGE_EXIT_CODE:-64}
}

warn() {
    echo -n "$0: " >&2
    echo -e "warning: $@" >&2
}

err() {
    echo "error: $@" >&2
    exit 1
}

###############################################################################
## MAIN
###############################################################################


while [[ $# -gt 0 ]]; do
    case "$1" in
       -l|--log)    FXTRACE_LOG=$2;    shift 2 ;;
       -m|--mode)   FXTRACE_MODE=$2;   shift 2 ;;
       -p|--prefix) FXTRACE_PREFIX=$2; shift 2 ;;
       -d|--debug)  FXTRACE_DEBUG=1;   shift   ;;
       -h|--help)   USAGE_EXIT_CODE=0 usage; break ;;
       --) shift; break ;;
       -*) usage; break ;;
       * ) break ;;
    esac
done


# check library only when it's path given
if [[ $( expr index "$FXTRACE_LIB_PATH" / || true ) -ne 0 ]]; then
    if [[ ${FXTRACE_LIB_PATH:0:1} = '/' ]]; then
        readlink -f "$FXTRACE_LIB_PATH" >/dev/null 2>&1 || err "$FXTRACE_LIB_PATH nor found or not proper link"
    else
        # do not allow relative path since cmd may do `cd somethere && exec something'
        abspath=$( readlink -f "$FXTRACE_LIB_PATH" ) || err "requred lib ($FXTRACE_LIB_PATH) not found"
        FXTRACE_LIB_PATH=$abspath
    fi
fi

[[ $# -gt 0 ]] || usage "no cmd param found"
[[ -n $FXTRACE_LOG ]] || usage "--log is necessary param"

if [[ -n $FXTRACE_MODE ]]; then
    rest=$( echo -n -- "$FXTRACE_MODE" | tr -d rwxs )
    [[ -z $rest ]] || usage "extra symbol(s) in --mode ($rest)"
    export FXTRACE_MODE
fi

if [[ -n $FXTRACE_PREFIX ]]; then
    [[ ${FXTRACE_PREFIX:0:1} = '/' ]] || warn "prefix doesn't look as absolute path!\nTrace messages will not appear"
    export FXTRACE_PREFIX
fi

[[ -n $FXTRACE_DEBUG ]] && export FXTRACE_DEBUG

# we have to clear logfile since fxtrace.so will only append to it
: >$FXTRACE_LOG
export FXTRACE_LOG

env LD_PRELOAD="$FXTRACE_LIB_PATH" "$@"
