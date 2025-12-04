#!/usr/bin/env bash
# Sublime Text adapter

cmd="$1"
worktree_path="$2"

# Find Sublime Text executable
find_sublime() {
    if command -v subl >/dev/null 2>&1; then
        echo "subl"
        return 0
    fi
    
    # Common installation paths
    local paths=(
        "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl"
        "/Applications/Sublime Text 4.app/Contents/SharedSupport/bin/subl"
        "/opt/sublime_text/sublime_text"
        "/usr/local/bin/subl"
        "/usr/bin/subl"
    )
    
    for path in "${paths[@]}"; do
        if [ -x "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    echo "subl"  # Fallback
    return 1
}

sublime_bin=$(find_sublime)

case "$cmd" in
    open)
        if ! command -v "$sublime_bin" >/dev/null 2>&1; then
            echo "Sublime Text not found. Please install it or add it to your PATH." >&2
            exit 1
        fi
        
        # Create project file if it doesn't exist
        local project_file="$worktree_path/$(basename "$worktree_path").sublime-project"
        if [ ! -f "$project_file" ]; then
            cat > "$project_file" << PROJECT_EOF
{
    "folders": [
        {
            "path": "."
        }
    ],
    "settings": {
        "tab_size": 2,
        "translate_tabs_to_spaces": true
    }
}
PROJECT_EOF
        fi
        
        # Open Sublime Text with the project
        "$sublime_bin" -a "$worktree_path" "$worktree_path" >/dev/null 2>&1 &
        ;;
        
    *)
        echo "Unknown command: $cmd" >&2
        exit 1
        ;;
esac
