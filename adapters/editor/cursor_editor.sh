#!/usr/bin/env bash
cmd="$1"
worktree="$2"
case "$cmd" in
  open)
    if command -v cursor >/dev/null 2>&1; then
      cursor open "$worktree" >/dev/null 2>&1 &
    else
      echo "Cursor CLI not found"
      exit 1
    fi
    ;;
esac
