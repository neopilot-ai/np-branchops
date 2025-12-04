# ui.sh - small UI helpers
confirm() {
  prompt="$1"
  read -r -p "$prompt [y/N]: " ans
  case "$ans" in
    [Yy]*) return 0 ;;
    *) return 1 ;;
  esac
}
