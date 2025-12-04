#!/usr/bin/env bash
cmd="$1"
worktree="$2"
case "$cmd" in
  open)
    if command -v aider >/dev/null 2>&1; then
      (cd "$worktree" && aider) &
    else
      echo "aider not found on PATH"
      exit 1
    fi
    ;;
esac
