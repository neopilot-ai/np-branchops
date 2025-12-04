# copy.sh - selective copy helper
copy_files_to_worktree() {
  src_dir="$1"
  dst_dir="$2"
  files_csv="$3"
  IFS=',' read -r -a files <<< "$files_csv"
  for f in "${files[@]}"; do
    f_trim="$(echo "$f" | xargs)"
    [ -z "$f_trim" ] && continue
    if [ -f "$src_dir/$f_trim" ]; then
      mkdir -p "$(dirname "$dst_dir/$f_trim")"
      cp "$src_dir/$f_trim" "$dst_dir/$f_trim"
      echo "Copied $f_trim"
    fi
  done
}
