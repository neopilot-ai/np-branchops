#!/usr/bin/env bash
# Zed editor adapter with enhanced features

cmd="$1"
worktree_path="$2"

zed_bin="zed"
if ! command -v "$zed_bin" >/dev/null 2>&1; then
    # Try common installation paths
    if [ -x "$HOME/.local/bin/zed" ]; then
        zed_bin="$HOME/.local/bin/zed"
    elif [ -x "/opt/zed/zed" ]; then
        zed_bin="/opt/zed/zed"
    else
        echo "Zed editor not found. Please install Zed and ensure it's in your PATH." >&2
        exit 1
    fi
fi

case "$cmd" in
    open)
        # Create a workspace file if it doesn't exist
        local workspace_file="$worktree_path/zed.code-workspace"
        if [ ! -f "$workspace_file" ]; then
            cat > "$workspace_file" << WORKSPACE_EOF
{
    "folders": [
        {
            "path": "."
        }
    ],
    "settings": {
        "zed.workspaceName": "$(basename "$worktree_path")"
    }
}
WORKSPACE_EOF
        fi

        # Open Zed with the workspace
        "$zed_bin" "$worktree_path" >/dev/null 2>&1 &
        ;;
    *)
        echo "Unknown command: $cmd" >&2
        exit 1
        ;;
esac
