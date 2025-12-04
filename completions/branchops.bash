# bash completion for branchops
_branchops() {
  local cur prev opts
  COMPREPLY=()
  _get_comp_words_by_ref -n : cur prev
  
  # Available commands
  local cmds="create remove list open switch edit completions"
  
  # Available editors and AI tools from manifest
  local editors=($(grep -oP 'AVAILABLE_EDITORS=\(\K[^)]+' $DIR/../adapters/manifest.sh | tr ' ' '\n' | tr -d "'" | tr '\n' ' '))
  local ai_tools=($(grep -oP 'AVAILABLE_AI=\(\K[^)]+' $DIR/../adapters/manifest.sh | tr ' ' '\n' | tr -d "'" | tr '\n' ' '))
  
  if [[ ${#COMP_WORDS[@]} -eq 2 ]]; then
    # First argument - complete with commands
    COMPREPLY=($(compgen -W "$cmds" -- "$cur"))
  else
    case "${COMP_WORDS[1]}" in
      create|open|edit)
        if [[ $prev == --editor ]]; then
          COMPREPLY=($(compgen -W "${editors[*]}" -- "$cur"))
        elif [[ $prev == --ai ]]; then
          COMPREPLY=($(compgen -W "${ai_tools[*]}" -- "$cur"))
        elif [[ $prev == --copy ]]; then
          # Complete with common config files
          COMPREPLY=($(compgen -W ".env .env.local .env.example config.json" -- "$cur"))
        else
          # Complete with branch names for certain commands
          if [[ ${COMP_WORDS[1]} == "open" || ${COMP_WORDS[1]} == "switch" || ${COMP_WORDS[1]} == "edit" ]]; then
            local branches=$(git branch --format='%(refname:short)' 2>/dev/null)
            COMPREPLY=($(compgen -W "$branches" -- "$cur"))
          fi
        fi
        ;;
      completions)
        COMPREPLY=($(compgen -W "bash zsh fish" -- "$cur"))
        ;;
    esac
  fi
  
  __ltrim_colon_completions "$cur"
}

complete -F _branchops branchops
