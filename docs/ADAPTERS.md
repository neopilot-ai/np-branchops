# BranchOps Adapter System

## Overview

The BranchOps adapter system extends the CLI's functionality by adding support for various editors and AI tools. This document explains how to use existing adapters and create new ones.

## Available Adapters

### Editors

- `vscode` - Visual Studio Code
- `vscode_remote` - VS Code with Remote Containers/SSH
- `nvim` - Neovim
- `vim` - Vim
- `emacs` - Emacs
- `zed` - Zed Editor
- `cursor` - Cursor Editor
- `idea` - IntelliJ IDEA
- `webstorm` - WebStorm
- `atom` - Atom

### AI Tools

- `aider` - Aider AI coding assistant
- `claude` - Claude AI
- `continue` - Continue AI
- `codex` - OpenAI Codex

## Using Adapters

### Specifying Adapters

```bash
# Use a specific editor
branchops create my-feature --editor=vscode

# Use an AI tool
branchops create my-feature --ai=claude

# Use multiple adapters
branchops create my-feature --editor=vscode --ai=codex
```

### Configuration

Adapters can be configured through environment variables or config files:

1. Global config: `~/.config/neopilot/config` 
2. Project config: `.branchops/config` 

Example configuration:

```bash
# Default editor and AI
DEFAULT_EDITOR="vscode"
DEFAULT_AI="claude"

# Adapter-specific settings
VSCODE_PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
```

## Creating Custom Adapters

### Editor Adapters

1. Create a new file in `adapters/editor/` named `{name}_editor.sh` 
2. Implement the required functions:

```bash
#!/usr/bin/env bash

# Required: Handle the 'open' command
# $1 - Command (always 'open' for now)
# $2 - Worktree path
case "$1" in
    open)
        # Your code to open the editor
        # Example: vim "$2"
        ;;
    *)
        echo "Unknown command: $1" >&2
        exit 1
        ;;
esac
```

### AI Adapters

1. Create a new file in `adapters/ai/` named `{name}_ai.sh` 
2. Implement the required functions:

```bash
#!/usr/bin/env bash

# Required: Handle the 'open' command
# $1 - Command (open, analyze, etc.)
# $2 - Worktree path
case "$1" in
    open)
        # Initialize AI session
        ;;
    analyze)
        # Analyze codebase
        ;;
    *)
        echo "Unknown command: $1" >&2
        exit 1
        ;;
esac
```

## Advanced Features

### Adapter Hooks

Adapters can define hooks that run at different stages:

```bash
# In your adapter script
run_hook "pre_open" "$worktree_path"
# Your open logic
run_hook "post_open" "$worktree_path"
```

### Environment Variables

- `NEOPILOT_DRY_RUN` - Set to 1 to enable dry-run mode
- `NEOPILOT_DEBUG` - Enable debug output
- `NEOPILOT_ASSUME_YES` - Skip confirmation prompts

## Best Practices

1. **Error Handling**: Always check for command existence and fail gracefully
2. **Idempotency**: Ensure your adapter can be run multiple times safely
3. **Configuration**: Use environment variables for configuration
4. **Documentation**: Document your adapter's requirements and options
5. **Testing**: Test your adapter with different scenarios

## Example: Creating a New Editor Adapter

Let's create a simple adapter for the `micro` editor:

1. Create `adapters/editor/micro_editor.sh`:

```bash
#!/usr/bin/env bash

case "$1" in
    open)
        if ! command -v micro >/dev/null 2>&1; then
            echo "Error: micro editor not found" >&2
            exit 1
        fi
        # Open in a new terminal window
        if [ -n "$TERMINAL" ]; then
            $TERMINAL -e "cd '$2' && micro" &
        else
            micro "$2"
        fi
        ;;
    *)
        echo "Unknown command: $1" >&2
        exit 1
        ;;
esac
```

2. Update [adapters/manifest.sh](cci:7://file:///Users/neopilot/neopilot-branchops/adapters/manifest.sh:0:0-0:0) to include your new adapter.

## Troubleshooting

### Debugging Adapters

```bash
# Enable debug output
NEOPILOT_DEBUG=1 branchops create test --editor=your_editor

# Check adapter availability
branchops adapters list
```

### Common Issues

1. **Permission Denied**: Make sure your adapter script is executable:
   ```bash
   chmod +x adapters/editor/your_editor.sh
   ```

2. **Command Not Found**: Ensure the editor/AI tool is installed and in your PATH

3. **Adapter Not Found**: Verify the adapter is listed in the appropriate array in [adapters/manifest.sh](cci:7://file:///Users/neopilot/neopilot-branchops/adapters/manifest.sh:0:0-0:0)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for your adapter
4. Submit a pull request

## License

[Your License Here]
