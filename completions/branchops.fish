# fish completion for branchops

function __fish_branchops_using_command
    set -l cmd (commandline -opc)
    if [ (count $cmd) -eq 1 -a "$cmd[1]" = 'branchops' ]
        return 0
    end
    return 1
end

# Commands
complete -c branchops -f -n '__fish_branchops_using_command' \
    -a 'create' -d 'Create a new worktree'
complete -c branchops -f -n '__fish_branchops_using_command' \
    -a 'remove' -d 'Remove a worktree'
complete -c branchops -f -n '__fish_branchops_using_command' \
    -a 'list' -d 'List all worktrees'
complete -c branchops -f -n '__fish_branchops_using_command' \
    -a 'open' -d 'Open a worktree in editor'
complete -c branchops -f -n '__fish_branchops_using_command' \
    -a 'switch' -d 'Switch to a worktree'
complete -c branchops -f -n '__fish_branchops_using_command' \
    -a 'edit' -d 'Edit worktree configuration'
complete -c branchops -f -n '__fish_branchops_using_command' \
    -a 'completions' -d 'Generate shell completions'

# Editor options
complete -c branchops -n '__fish_seen_subcommand_from create open edit' \
    -l editor -d 'Specify editor' -r -f -a "vscode nvim vim emacs cursor zed idea webstorm atom"

# AI options
complete -c branchops -n '__fish_seen_subcommand_from create open' \
    -l ai -d 'Specify AI tool' -r -f -a "aider claude continue codex"

# Copy options
complete -c branchops -n '__fish_seen_subcommand_from create' \
    -l copy -d 'Copy files' -r -f -a ".env .env.local .env.example config.json"

# Branch completion
complete -c branchops -n '__fish_seen_subcommand_from open switch edit remove' \
    -a '(git branch --format=\'%(refname:short)\'' 2>/dev/null)' -f

# Completions subcommand
complete -c branchops -n '__fish_seen_subcommand_from completions' \
    -a 'bash zsh fish' -f
