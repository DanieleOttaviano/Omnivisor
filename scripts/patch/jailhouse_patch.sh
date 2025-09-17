#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Apply a patch to Jailhouse

Usage:
  $0 [options]

Options:
  -p, --patch <file>   Patch file to apply (from custom_jailhouse_patch_dir)
  -t, --target <val>   Target board/platform
  -b, --backend <val>  Backend (e.g. jailhouse)
  -h, --help           Show this help message
EOF
  exit 1
}

# Directories & helpers
current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "$current_dir")
source "$script_dir/common/common.sh"

PATCH=""

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--patch)   PATCH="$2"; shift 2 ;;
    -t|--target)  TARGET="$2"; shift 2 ;;
    -b|--backend) BACKEND="$2"; shift 2 ;;
    -h|--help)    usage ;;
    *) error "Unknown option: $1"; usage ;;
  esac
done

# Load environment
source "$script_dir/common/set_environment.sh" "$TARGET" "$BACKEND"

# Apply patch
if [[ -z "$PATCH" ]]; then
  warn "No patch specified. Skipping patch application."
  exit 0
fi

patch_path="$custom_jailhouse_patch_dir/$PATCH"

if [[ -f "$patch_path" ]]; then
  info "Applying patch: $PATCH"
  if patch -p1 -d "$jailhouse_dir" < "$patch_path"; then
    success "Patch $PATCH applied successfully!"
  else
    error "Failed to apply patch: $PATCH"
    exit 1
  fi
else
  error "Patch not found: $patch_path"
  echo "Available patches in $custom_jailhouse_patch_dir:"
  ls "$custom_jailhouse_patch_dir"
  exit 1
fi