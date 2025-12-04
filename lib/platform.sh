# platform.sh - platform detection
detect_shell() {
  printf '%s' "${SHELL##*/}"
}
is_git_repo_root() {
  git rev-parse --show-toplevel >/dev/null 2>&1
}
