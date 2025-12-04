#!/usr/bin/env bash

# Create config directory if it doesn't exist
CONFIG_DIR="$HOME/.config/neopilot"
CONFIG_FILE="$CONFIG_DIR/claude"

# Check if the config file already exists
if [ -f "$CONFIG_FILE" ]; then
    echo "⚠️  Claude configuration already exists at $CONFIG_FILE"
    echo "Current configuration:"
    echo "---------------------"
    cat "$CONFIG_FILE"
    echo -e "\nDo you want to update it? (y/N)"
    read -r update_config
    if [[ ! "$update_config" =~ ^[Yy]$ ]]; then
        echo "Configuration not updated."
        exit 0
    fi
fi

# Get the API key
echo "🔑 Please enter your Claude API key:"
read -r -s CLAUDE_API_KEY

# Validate the API key (basic validation)
if [[ ! "$CLAUDE_API_KEY" =~ ^sk-ant- ]]; then
    echo "❌ Invalid API key format. It should start with 'sk-ant-'"
    exit 1
fi

# Write the configuration
cat > "$CONFIG_FILE" << CONFIG
# Claude API Configuration
export CLAUDE_API_KEY="$CLAUDE_API_KEY"
# Optional: Set the model (default: claude-3-opus-20240229)
# export CLAUDE_MODEL="claude-3-opus-20240229"
CONFIG

# Set secure permissions
chmod 600 "$CONFIG_FILE"

echo -e "\n✅ Claude API key has been saved to $CONFIG_FILE"
echo "To use it in your current shell, run:"
echo "  source $CONFIG_FILE"
echo -e "\nTo make it available in all new terminal sessions, add this to your shell profile:"
echo "  echo 'source $CONFIG_FILE' >> ~/.$(basename "$SHELL")rc"
