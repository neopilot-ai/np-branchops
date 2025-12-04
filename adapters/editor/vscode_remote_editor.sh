#!/usr/bin/env bash
# VS Code Remote adapter
# Supports opening workspaces in VS Code with remote containers or SSH

cmd="$1"
worktree_path="$2"

# Check if VS Code CLI is available
if ! command -v code >/dev/null 2>&1; then
    echo "VS Code CLI 'code' not found in PATH" >&2
    exit 1
fi

case "$cmd" in
    open)
        # Check if inside a container
        if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
            # Inside container, open regularly
            code "$worktree_path" --new-window >/dev/null 2>&1 &
        else
            # Try to determine if we should use remote containers
            if [ -f "$worktree_path/.devcontainer/devcontainer.json" ]; then
                # Open with remote containers
                code --remote ssh-remote+$(hostname) "$worktree_path" >/dev/null 2>&1 &
            else
                # Regular VS Code open
                code "$worktree_path" --new-window >/dev/null 2>&1 &
            fi
        fi
        ;;
    *)
        echo "Unknown command: $cmd" >&2
        exit 1
        ;;
esac
