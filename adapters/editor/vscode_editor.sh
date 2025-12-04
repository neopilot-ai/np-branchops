#!/usr/bin/env bash
cmd="$1"
worktree="$2"
case "$cmd" in
  open)
    code "$worktree" >/dev/null 2>&1 &
    ;;
  *)
    echo "unknown"
    ;;
esac
