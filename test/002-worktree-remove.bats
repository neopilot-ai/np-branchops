#!/usr/bin/env bats

setup() {
  TMP=$(mktemp -d)
  cd "$TMP"
  git init >/dev/null
  git commit --allow-empty -m "init" >/dev/null
  BOP="$(pwd)/../../bin/branchops"
  [ -f "$BOP" ] || skip "branchops binary not found at $BOP"
  
  # Create a worktree for testing removal
  git worktree add -b test-branch test-worktree >/dev/null 2>&1 || true
}

teardown() {
  # Clean up any worktrees
  git worktree remove --force test-worktree 2>/dev/null || true
  git worktree prune
  rm -rf "$TMP"
}

@test "remove non-existent worktree returns failure" {
  run "$BOP" remove non-existent-branch
  [ "$status" -ne 0 ]
}

@test "remove existing worktree" {
  # First create a worktree to remove
  "$BOP" create test-remove --editor=vscode
  
  # Now try to remove it
  run "$BOP" remove test-remove
  [ "$status" -eq 0 ]
  [ ! -d "$TMP/.worktrees/test-remove" ]
}

@test "remove worktree with force flag" {
  # Create a worktree with uncommitted changes
  "$BOP" create dirty-worktree
  cd .worktrees/dirty-worktree
  echo "uncommitted" > file.txt
  
  # Try to remove with force
  cd "$TMP"
  NEOPILOT_ASSUME_YES=1 run "$BOP" remove dirty-worktree
  [ "$status" -eq 0 ]
  [ ! -d "$TMP/.worktrees/dirty-worktree" ]
}

@test "remove worktree with dry run" {
  "$BOP" create test-dry-remove
  
  NEOPILOT_DRY_RUN=1 run "$BOP" remove test-dry-remove
  [ "$status" -eq 0 ]
  [[ "${output}" =~ "dry-run" ]]
  # Verify it wasn't actually removed
  [ -d "$TMP/.worktrees/test-dry-remove" ]
}
