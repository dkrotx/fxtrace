#!/bin/bash

set -e
set -o pipefail

FXTRACE_LIB_PATH=${FXTRACE_LIB_PATH=@FXTRACE_SO_DIR@/libfxtrace.so}
FXTRACE_LOG=./fxtrace.log

usage() {
    if [[ -n $1 ]]; then
        echo "$0: wrong usage: " "$@"
    fi

    local progname=$( basename $0 )

    cat - >&2 <<ENDUSAGE
Usage: $progname [-l logfile] [-m mode] [-p prefix] [-d] cmd [...]

Options:
  -l|--log:    trace operations to specified file instead of $FXTRACE_LOG
  -m|--mode:   trace only specified operations. They are:
                 r - open for read
                 w - open for write
                 x - execute
                 s - stat(2)
 
  -p|--prefix:  log only files which fullpath starts with given prefix
  -d|--debug:   print each event to stderr

EXAMPLES:

- Simple case:
  $ $progname cat /etc/fstab # $FXTRACE_LOG will contain log

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

extract_longopt_value() {
    local var=$1
    local value=${2#*=}

    [[ -n $value ]] || usage
    eval $var="$value"
}

###############################################################################
## MAIN
###############################################################################


while [[ $# -gt 0 ]]; do
    case "$1" in
        -l|--log)     FXTRACE_LOG=$2;     shift 2 ;;
        -m|--mode)    FXTRACE_MODE=$2;    shift 2 ;;
        -p|--prefix)  FXTRACE_PREFIX=$2;  shift 2 ;;
        -d|--debug)   FXTRACE_DEBUG=1;    shift ;;
        -h|--help*)   USAGE_EXIT_CODE=0 usage; break ;;

        
        --log=*)    extract_longopt_value FXTRACE_LOG "$1";    shift ;;
        --mode=*)   extract_longopt_value FXTRACE_MODE "$1";   shift ;;
        --prefix=*) extract_longopt_value FXTRACE_PREFIX "$1"; shift ;;

        # support GNU longops for booleans too (--debug=1). why not?
        --debug=*)   extract_longopt_value FXTRACE_DEBUG "$1";   shift ;;

        --) shift; break ;; # end of options
        -*) usage; break ;; # unknown option
        * ) break ;;        # hit 'cmd'
    esac
done


# check library only when it's path given
if [[ $( expr index "$FXTRACE_LIB_PATH" / || true ) -ne 0 ]]; then
    if [[ ${FXTRACE_LIB_PATH:0:1} = '/' ]]; then
        readlink -e "$FXTRACE_LIB_PATH" >/dev/null 2>&1 || err "$FXTRACE_LIB_PATH nor found or not proper link"
    else
        # do not allow relative path since cmd may do `cd somethere && exec something'
        abspath=$( readlink -e "$FXTRACE_LIB_PATH" ) || err "requred lib ($FXTRACE_LIB_PATH) not found"
        FXTRACE_LIB_PATH=$abspath
    fi
fi

[[ $# -gt 0 ]] || usage "no cmd param found"
[[ -n $FXTRACE_LOG ]] || usage "--log must not be empty"

# FXTRACE_LOG must be absolute path, since subprocess will reopen logfile
[[ ${FXTRACE_LOG:0:1} = '/' ]] || FXTRACE_LOG=$( readlink -f "$FXTRACE_LOG" )

if [[ -n $FXTRACE_MODE ]]; then
    rest=$( echo -n "$FXTRACE_MODE" | tr -d rwxs )
    [[ -z $rest ]] || usage "extra symbol(s) in --mode ($rest)"
    export FXTRACE_MODE
fi

if [[ -n $FXTRACE_PREFIX ]]; then
    [[ ${FXTRACE_PREFIX:0:1} = '/' ]] || FXTRACE_PREFIX=$( readlink -m "$FXTRACE_PREFIX" )
    export FXTRACE_PREFIX
fi

[[ -n $FXTRACE_DEBUG ]] && export FXTRACE_DEBUG

# we have to clear logfile since fxtrace.so will only append to it
: >$FXTRACE_LOG
export FXTRACE_LOG

env LD_PRELOAD="$FXTRACE_LIB_PATH" "$@"
