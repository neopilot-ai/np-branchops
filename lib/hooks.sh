# hooks.sh - hook runner
run_hook() {
  hook_name="$1"
  worktree_path="$2"
  hook_file="./hooks/$hook_name"
  if [ -f "$hook_file" ]; then
    echo "Running repo hook: $hook_file"
    (cd "$worktree_path" && bash "$hook_file" "$worktree_path")
  fi
  # user-level hooks in worktree
  if [ -f "$worktree_path/.branchops/hooks/$hook_name" ]; then
    echo "Running worktree hook"
    (cd "$worktree_path" && bash ".branchops/hooks/$hook_name" "$worktree_path")
  fi
}
