#!/usr/bin/env bash
# lib/core/worktree.sh - improved: safe naming, checks, dry-run, interactive, adapters check
set -euo pipefail

# NOTE: This file expects the following helper functions to be available:
#   die(), info(), success(), debug(), run_hook(), copy_files_to_worktree()
# and variables:
#   DIR (repo root where `adapters/` lives)
# and the adapters manifest: adapters/manifest.sh (defines AVAILABLE_EDITORS and AVAILABLE_AI)

# Helper: sanitize branch/worktree name to a safe Git ref-ish fragment
sanitize_name() {
  local name="$1"
  # lower-case, replace spaces with -, remove unsafe chars
  name="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[[:space:]]+/-/g' | sed -E 's/[^a-z0-9._-]//g')"
  # trim leading/trailing dots/dashes/underscores
  name="$(printf '%s' "$name" | sed -E 's/^[._-]+//; s/[._-]+$//')"
  # limit length
  name="${name:0:200}"
  printf '%s' "$name"
}

# Git helpers
branch_exists() {
  local branch="$1"
  git show-ref --verify --quiet "refs/heads/$branch"
}

worktree_exists() {
  local path="$1"
  [ -d "$path" ]
}

worktree_for_branch() {
  local branch="$1"
  git worktree list --porcelain 2>/dev/null | awk -v b="$branch" '
    $1=="worktree" { w=$2 }
    $1=="branch" && $2==("refs/heads/" b) { print w }
  '
}

# Determine base repo top
repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || printf '%s' "$(pwd)"
}

# verify adapter availability using adapters/manifest.sh (optional)
_check_adapter() {
  local type="$1"   # editor | ai
  local name="$2"
  [ -z "$name" ] && return 0
  # source manifest if present
  if [ -f "$DIR/adapters/manifest.sh" ]; then
    # shellcheck source=/dev/null
    source "$DIR/adapters/manifest.sh"
  fi
  if [ "$type" = "editor" ]; then
    for e in "${AVAILABLE_EDITORS[@]:-}"; do
      [ "$e" = "$name" ] && return 0
    done
    return 1
  else
    for a in "${AVAILABLE_AI[@]:-}"; do
      [ "$a" = "$name" ] && return 0
    done
    return 1
  fi
}

# Public functions -----------------------------------------------------------

# list worktrees (enhanced)
worktree_list() {
  info "Listing git worktrees in repo: $(repo_root)"
  git worktree list || info "(no worktrees)"
}

# create worktree
# args: name, editor, copy_list, ai, opts...
# supports environment:
#   NEOPILOT_DRY_RUN=1  -> show actions only
#   NEOPILOT_ASSUME_YES=1 -> don't prompt
worktree_create() {
  local raw_name="$1"
  local editor="${2:-}"
  local copy_list="${3:-}"
  local ai="${4:-}"
  shift 4 || true

  [ -z "$raw_name" ] && die "worktree_create: name required"
  # sanitize
  local name
  name="$(sanitize_name "$raw_name")"
  [ -z "$name" ] && die "Invalid name after sanitization"

  local dry_run="${NEOPILOT_DRY_RUN:-0}"
  local assume_yes="${NEOPILOT_ASSUME_YES:-0}"

  # check git repo
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Not a git repo"

  local base_dir
  base_dir="$(git rev-parse --show-toplevel)"
  local wt_root="$base_dir/.worktrees"
  local wt_dir="$wt_root/$name"

  # conflict detection
  if worktree_exists "$wt_dir"; then
    die "Worktree path already exists: $wt_dir"
  fi

  local existing_wt
  existing_wt="$(worktree_for_branch "$name" || true)"
  if [ -n "$existing_wt" ]; then
    info "Found existing worktree for branch '$name' at: $existing_wt"
    if [ "$assume_yes" != "1" ]; then
      if ! confirm "A worktree already exists for branch '$name' at $existing_wt. Continue and create another at $wt_dir?"; then
        die "Aborted by user"
      fi
    fi
  fi

  # adapters sanity checks
  if [ -n "$editor" ] && ! _check_adapter editor "$editor"; then
    die "Unknown editor adapter: $editor"
  fi
  if [ -n "$ai" ] && ! _check_adapter ai "$ai"; then
    die "Unknown AI adapter: $ai"
  fi

  info "Will create worktree '$name' at $wt_dir"
  if [ "$dry_run" = "1" ]; then
    info "[dry-run] mkdir -p '$wt_dir'"
    info "[dry-run] git worktree add '$wt_dir' -b '$name'"
    [ -n "$copy_list" ] && info "[dry-run] copy files: $copy_list"
    return 0
  fi

  mkdir -p "$wt_root"
  # create worktree; if branch exists, add using branch ref, else create new branch (-b)
  if branch_exists "$name"; then
    info "Branch '$name' already exists; adding worktree from branch"
    git worktree add "$wt_dir" "$name" || die "git worktree add failed"
  else
    info "Creating new branch '$name' (from HEAD) and adding worktree"
    git worktree add "$wt_dir" -b "$name" || die "git worktree add failed"
  fi

  # copy requested files
  if [ -n "$copy_list" ]; then
    copy_files_to_worktree "$base_dir" "$wt_dir" "$copy_list"
  fi

  # write metadata
  mkdir -p "$wt_dir/.branchops/hooks"
  cat > "$wt_dir/.branchops/meta" <<EOF
name=$name
created_at=$(date --iso-8601=seconds 2>/dev/null || date)
editor=${editor:-}
ai=${ai:-}
origin_repo=$(basename "$base_dir")
EOF

  # run repo-level and worktree-level hooks
  run_hook post-create "$wt_dir"

  # try to open editor and/or AI if requested (best-effort)
  if [ -n "$editor" ]; then
    local editor_script="$DIR/adapters/editor/${editor}_editor.sh"
    if [ -x "$editor_script" ]; then
      info "Launching editor: $editor"
      "$editor_script" open "$wt_dir" || info "editor adapter returned non-zero"
    else
      info "Editor adapter not found/executable: $editor_script"
    fi
  fi

  if [ -n "$ai" ]; then
    local ai_script="$DIR/adapters/ai/${ai}_ai.sh"
    if [ -x "$ai_script" ]; then
      info "Launching AI tool: $ai (background)"
      "$ai_script" open "$wt_dir" || info "ai adapter returned non-zero"
    else
      info "AI adapter not found/executable: $ai_script"
    fi
  fi

  success "Worktree '$name' created at: $wt_dir"
}

# remove worktree
# args: name
worktree_remove() {
  local raw_name="$1"
  [ -z "$raw_name" ] && die "name required"
  local name
  name="$(sanitize_name "$raw_name")"
  local base_dir
  base_dir="$(git rev-parse --show-toplevel)"
  local wt_dir="$base_dir/.worktrees/$name"
  local dry_run="${NEOPILOT_DRY_RUN:-0}"
  local assume_yes="${NEOPILOT_ASSUME_YES:-0}"

  if [ ! -d "$wt_dir" ]; then
    # maybe it's a worktree for existing branch elsewhere
    local wt_for_branch
    wt_for_branch="$(worktree_for_branch "$name" || true)"
    if [ -n "$wt_for_branch" ]; then
      info "Worktree for branch '$name' found at $wt_for_branch (not under .worktrees). Will remove that instead."
      wt_dir="$wt_for_branch"
    else
      die "Worktree '$name' not found"
    fi
  fi

  if [ "$assume_yes" != "1" ]; then
    if ! confirm "Remove worktree at $wt_dir? This will attempt 'git worktree remove' and delete the directory."; then
      die "Aborted by user"
    fi
  fi

  if [ "$dry_run" = "1" ]; then
    info "[dry-run] git worktree remove '$wt_dir' || true"
    info "[dry-run] rm -rf '$wt_dir'"
    return 0
  fi

  # run hooks
  run_hook post-remove "$wt_dir"

  # attempt to detach/remove via git
  set +e
  git worktree remove "$wt_dir" >/dev/null 2>&1
  local rc=$?
  set -e
  if [ "$rc" -ne 0 ]; then
    info "git worktree remove returned non-zero; continuing to remove directory"
  fi

  rm -rf "$wt_dir" || die "failed to remove worktree dir"

  success "Worktree '$name' removed"
}

# open worktree with editor/ai (no creation)
worktree_open() {
  local raw_name="$1"
  local editor="${2:-}"
  local ai="${3:-}"

  [ -z "$raw_name" ] && die "name required"
  local name
  name="$(sanitize_name "$raw_name")"
  local base_dir
  base_dir="$(git rev-parse --show-toplevel)"
  local wt_dir="$base_dir/.worktrees/$name"
  if [ ! -d "$wt_dir" ]; then
    local alt
    alt="$(worktree_for_branch "$name" || true)"
    if [ -n "$alt" ]; then
      wt_dir="$alt"
    else
      die "Worktree '$name' not found"
    fi
  fi

  if [ -n "$editor" ]; then
    local editor_script="$DIR/adapters/editor/${editor}_editor.sh"
    if [ -x "$editor_script" ]; then
      "$editor_script" open "$wt_dir" || die "editor open failed"
    else
      die "Editor adapter not available: $editor"
    fi
  fi

  if [ -n "$ai" ]; then
    local ai_script="$DIR/adapters/ai/${ai}_ai.sh"
    if [ -x "$ai_script" ]; then
      "$ai_script" open "$wt_dir" || info "ai adapter failed (non-fatal)"
    else
      die "AI adapter not available: $ai"
    fi
  fi

  success "Opened: $wt_dir"
}

# switch (cd) into worktree
worktree_switch() {
  local raw_name="$1"
  [ -z "$raw_name" ] && die "name required"
  local name
  name="$(sanitize_name "$raw_name")"
  local base_dir
  base_dir="$(git rev-parse --show-toplevel)"
  local wt_dir="$base_dir/.worktrees/$name"
  if [ ! -d "$wt_dir" ]; then
    local alt
    alt="$(worktree_for_branch "$name" || true)"
    if [ -n "$alt" ]; then
      wt_dir="$alt"
    else
      die "Worktree '$name' not found"
    fi
  fi

  cd "$wt_dir" || die "failed to cd into worktree"
  success "Switched to $name (pwd: $(pwd))"
}

# edit alias (open editor)
worktree_edit() {
  worktree_open "$1" "$2"
}

# completion generator (very small)
generate_completions() {
  local shell="$1"
  case "$shell" in
    bash) cat "$DIR/completions/branchops.bash" ;;
    zsh) cat "$DIR/completions/branchops.zsh" ;;
    fish) cat "$DIR/completions/branchops.fish" ;;
    *) die "unsupported shell for completions: $shell" ;;
  esac
}
