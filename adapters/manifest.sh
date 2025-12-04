# Adapters manifest
# Lists all available editor and AI adapters

# Available editors
AVAILABLE_EDITORS=(
    "vscode"        # Visual Studio Code
    "vscode_remote" # VS Code with Remote Containers/SSH
    "nvim"          # Neovim
    "vim"           # Vim
    "emacs"         # Emacs
    "zed"           # Zed Editor
    "cursor"        # Cursor Editor
    "idea"          # IntelliJ IDEA
    "webstorm"      # WebStorm
    "atom"          # Atom
    "sublime"       # Sublime Text
)

# Available AI tools
AVAILABLE_AI=(
    "aider"         # Aider AI coding assistant
    "claude"        # Claude AI
    "continue"      # Continue AI
    "codex"         # OpenAI Codex
    "copilot"       # GitHub Copilot
)

# Verify an adapter exists
adapter_exists() {
    local type="$1"
    local name="$2"
    
    if [ "$type" = "editor" ]; then
        for editor in "${AVAILABLE_EDITORS[@]}"; do
            [ "$editor" = "$name" ] && return 0
        done
    elif [ "$type" = "ai" ]; then
        for ai in "${AVAILABLE_AI[@]}"; do
            [ "$ai" = "$name" ] && return 0
        done
    fi
    
    return 1
}
