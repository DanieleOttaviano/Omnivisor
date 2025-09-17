#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Patch Buildroot

Usage:
  $0 [options]

Options:
  -t, --target <val>    Target board/platform
  -b, --backend <val>   Backend (e.g. jailhouse)
  -p, --patch <file>    Apply a single patch
  -d, --dirs <d1,d2>    Apply all patches from comma-separated directories
  -h, --help            Show this help message
EOF
  exit 1
}

# Directories & helpers
curr_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "$curr_dir")
source "$script_dir/common/common.sh"

PATCH=""
PATCH_DIRS=()
ERROR=0

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target) TARGET="$2"; shift 2 ;;
    -b|--backend) BACKEND="$2"; shift 2 ;;
    -p|--patch) PATCH="$2"; shift 2 ;;
    -d|--dirs) IFS=',' read -r -a PATCH_DIRS <<< "$2"; shift 2 ;;
    -h|--help) usage ;;
    *) error "Unknown option: $1"; usage ;;
  esac
done

# Load environment
source "$script_dir/common/set_environment.sh" "$TARGET" "$BACKEND"

# Function to apply patches in a directory
apply_patches_in_dir() {
  local patch_dir="$1"
  local full_patch_dir="$custom_buildroot_patch_dir/$patch_dir"

  if [[ ! -d "$full_patch_dir" ]]; then
    error "Directory not found: $full_patch_dir"
    exit 1
  fi

  info "Processing patches from: $full_patch_dir"
  local patches
  patches=$(find "$full_patch_dir" -type f -name "*.patch" | sort)

  if [[ -z "$patches" ]]; then
    warn "No patches found in $full_patch_dir"
    return
  fi

  for patch_file in $patches; do
    info "Applying patch: $(basename "$patch_file")"
    if patch -p1 -d "$buildroot_dir" < "$patch_file"; then
      success "Applied: $(basename "$patch_file")"
    else
      error "Failed to apply patch: $(basename "$patch_file")"
      ERROR=1
    fi
  done
}

# Apply single patch
if [[ -n "$PATCH" ]]; then
  patch_file="$custom_buildroot_patch_dir/$PATCH"
  if [[ -f "$patch_file" ]]; then
    info "Applying single patch: $PATCH"
    if patch -p1 -d "$buildroot_dir" < "$patch_file"; then
      success "Patch $PATCH applied successfully"
    else
      error "Failed to apply patch: $PATCH"
      ERROR=1
    fi
  else
    error "Patch not found: $patch_file"
    echo "Available patches in $custom_buildroot_patch_dir:"
    ls "$custom_buildroot_patch_dir"
    exit 1
  fi
fi

# Apply from directories
if [[ ${#PATCH_DIRS[@]} -gt 0 ]]; then
  for dir in "${PATCH_DIRS[@]}"; do
    apply_patches_in_dir "$dir"
  done
fi

# Nothing specified
if [[ -z "$PATCH" && ${#PATCH_DIRS[@]} -eq 0 ]]; then
  warn "No patch or directories specified. Skipping patching."
fi

exit $ERROR