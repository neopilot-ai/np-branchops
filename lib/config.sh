# config.sh - load user defaults
NEOPILOT_CONFIG="${NEOPILOT_CONFIG:-$HOME/.config/neopilot/config}"
load_config() {
  if [ -f "$NEOPILOT_CONFIG" ]; then
    # shellcheck source=/dev/null
    source "$NEOPILOT_CONFIG"
  fi
}
