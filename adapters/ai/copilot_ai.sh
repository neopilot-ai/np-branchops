#!/usr/bin/env bash
# GitHub Copilot integration adapter

cmd="$1"
worktree_path="$2"

# Configuration
COPILOT_ACCESS_TOKEN="${COPILOT_ACCESS_TOKEN:-}"
COPILOT_API_URL="https://api.githubcopilot.com"

# Check for GitHub CLI
if ! command -v gh >/dev/null 2>&1; then
    echo "GitHub CLI (gh) is required for Copilot integration" >&2
    exit 1
fi

# Get or refresh token
get_copilot_token() {
    if [ -n "$COPILOT_ACCESS_TOKEN" ]; then
        echo "$COPILOT_ACCESS_TOKEN"
        return
    fi
    
    # Try to get token from GitHub CLI
    if token=$(gh auth token 2>/dev/null); then
        echo "$token"
        return
    fi
    
    echo "Error: Could not get GitHub Copilot token" >&2
    exit 1
}

case "$cmd" in
    open)
        token=$(get_copilot_token)
        
        # Get code context
        cd "$worktree_path" || exit 1
        context_file=$(mktemp)
        
        # Get recent changes
        git log -n 5 --pretty=format:"%h - %s (%an, %ar)" > "$context_file"
        echo -e "\n\nCurrent branch: $(git branch --show-current)\n" >> "$context_file"
        
        # Get current file if in editor
        if [ -n "$(git status --porcelain)" ]; then
            echo -e "\nUncommitted changes:\n" >> "$context_file"
            git diff --stat >> "$context_file"
        fi
        
        # Open Copilot in browser with context
        if command -v xdg-open >/dev/null; then
            xdg-open "https://github.com/features/copilot" >/dev/null 2>&1 &
        elif command -v open >/dev/null; then
            open "https://github.com/features/copilot" >/dev/null 2>&1 &
        fi
        
        echo "GitHub Copilot ready! Context:"
        cat "$context_file"
        rm -f "$context_file"
        ;;
        
    suggest)
        # Get code suggestion
        prompt="$3"
        if [ -z "$prompt" ]; then
            echo "Error: No prompt provided" >&2
            exit 1
        fi
        
        token=$(get_copilot_token)
        response=$(curl -s -X POST "$COPILOT_API_URL/v1/engines/copilot-codex/completions" \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" \
            -d '{
                "prompt": "'"$prompt"'",
                "max_tokens": 150,
                "temperature": 0.7
            }')
        
        echo "$response" | jq -r '.choices[0].text' 2>/dev/null || echo "Error getting suggestion"
        ;;
        
    *)
        echo "Unknown command: $cmd" >&2
        echo "Available commands: open, suggest" >&2
        exit 1
        ;;
esac
