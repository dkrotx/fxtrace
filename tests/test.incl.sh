set -e
set -o pipefail

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
