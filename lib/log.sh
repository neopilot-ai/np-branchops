# log.sh - logging helpers
info() { echo "[info] $*"; }
success() { echo "[ok] $*"; }
debug() { [ "${NEOPILOT_DEBUG:-}" = "1" ] && echo "[debug] $*"; }
