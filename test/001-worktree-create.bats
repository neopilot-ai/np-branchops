#!/usr/bin/env bats

setup() {
  TMP=$(mktemp -d)
  cd "$TMP"
  git init >/dev/null
  mkdir -p repo
  cd repo
  git init >/dev/null
  # create initial commit
  git commit --allow-empty -m "init" >/dev/null
  # symlink the cli to PATH (adjust path to your project during CI)
  BOP="$(pwd)/../../bin/branchops"
  [ -f "$BOP" ] || skip "branchops binary not found at $BOP"
}

teardown() {
  rm -rf "$TMP"
}

@test "create worktree (dry-run) succeeds without side effects" {
  NEOPILOT_DRY_RUN=1 run "$BOP" create feature/test --editor=vscode
  [ "$status" -eq 0 ]
  [[ "${output}" =~ "dry-run" ]]
}

@test "create worktree with invalid editor fails" {
  run "$BOP" create feature/test --editor=nonexistent-editor
  [ "$status" -ne 0 ]
  [[ "${output}" =~ "unknown editor" || "${output}" =~ "not available" ]]
}

@test "create worktree with copy list" {
  # Create test files to copy
  echo "test" > .env
  git add .env
  git commit -m "Add .env" >/dev/null
  
  NEOPILOT_DRY_RUN=1 run "$BOP" create feature/test --copy=.env
  [ "$status" -eq 0 ]
  [[ "${output}" =~ "copy" ]]
  [[ "${output}" =~ ".env" ]]
}

@test "create worktree with AI integration" {
  NEOPILOT_DRY_RUN=1 run "$BOP" create feature/test --ai=aider
  [ "$status" -eq 0 ]
  [[ "${output}" =~ "aider" ]]
}
