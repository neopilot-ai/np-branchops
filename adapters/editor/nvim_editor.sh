#!/usr/bin/env bash
cmd="$1"
worktree="$2"
case "$cmd" in
  open) (cd "$worktree" && nvim) ;;
esac
