# errors.sh - common exit helper
err() {
  echo "ERROR: $*" >&2
}
die() {
  err "$*"
  exit 1
}
