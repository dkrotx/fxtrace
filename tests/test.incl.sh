err() {
    echo "Error: " "$@" >&2
    exit 1
}

assert_file_contains() {
    file=$1
    shift

    [[ -e $file ]] || err "$file not found"

    while [[ $# -gt 0 ]]; do
        grep -q "$1" "$file" || err "string \"$1\" not found in file $file"
        shift
    done
}
