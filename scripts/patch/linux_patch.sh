#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Apply or remove Linux patches

Usage:
  $0 [-p <patch>] [-d <dir1,dir2,...>] [-r]

Options:
  -p, --patch <file>      Apply/remove a single patch
  -d, --dirs <list>       Comma-separated list of patch directories
  -r, --remove            Remove patches instead of applying them
  -t, --target <val>      Target board/platform
  -b, --backend <val>     Backend (e.g. jailhouse)
  -h, --help              Show this help message
EOF
  exit 1
}

# Directories & helpers
current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "$current_dir")
source "$script_dir/common/common.sh"

# Defaults
REMOVE=""
PATCH=""
PATCH_DIRS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--patch) PATCH="$2"; shift 2 ;;
    -d|--dirs) IFS=',' read -r -a PATCH_DIRS <<< "$2"; shift 2 ;;
    -r|--remove) REMOVE="-R"; shift ;;
    -t|--target) TARGET="$2"; shift 2 ;;
    -b|--backend) BACKEND="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) error "Unknown option: $1"; usage ;;
  esac
done

# Load environment
source "$script_dir/common/set_environment.sh" "$TARGET" "$BACKEND"

# Operation mode
if [[ -n "$REMOVE" ]]; then
  OPERATION="removing"
  OPERATION2="removed"
else
  OPERATION="applying"
  OPERATION2="applied"
fi

apply_patches_in_dir() {
  local patch_dir="$1"
  local full_dir="$custom_linux_patch_dir/$patch_dir"

  if [[ ! -d "$full_dir" ]]; then
    error "Directory not found: $full_dir"
    exit 1
  fi

  info "Processing patches from: $full_dir"
  local patches
  patches=$(find "$full_dir" -type f -name "*.patch" | sort)

  if [[ -z "$patches" ]]; then
    warn "No patches found in: $full_dir"
    return
  fi

  local failed=0
  for patch_file in $patches; do
    info "${OPERATION^} patch: $(basename "$patch_file")"
    if ! patch $REMOVE -p1 -d "$linux_dir" < "$patch_file"; then
      error "Failed ${OPERATION} patch: $(basename "$patch_file")"
      failed=1
    fi
  done

  if [[ $failed -eq 0 ]]; then
    success "All patches from $full_dir ${OPERATION2} successfully."
  else
    error "Some patches in $full_dir failed."
  fi
}

# Single patch
if [[ -n "$PATCH" ]]; then
  local_patch="$custom_linux_patch_dir/$PATCH"
  if [[ ! -f "$local_patch" ]]; then
    error "Patch not found: $PATCH"
    info "Available patches:"
    ls "$custom_linux_patch_dir"
    exit 1
  fi

  info "${OPERATION^} single patch: $PATCH"
  if patch $REMOVE -p1 -d "$linux_dir" < "$local_patch"; then
    success "Patch $PATCH ${OPERATION2} successfully."
  else
    error "Failed ${OPERATION} patch: $PATCH"
  fi
fi

# Directories
if [[ ${#PATCH_DIRS[@]} -gt 0 ]]; then
  for dir in "${PATCH_DIRS[@]}"; do
    apply_patches_in_dir "$dir"
  done
fi

# Nothing specified
if [[ -z "$PATCH" && ${#PATCH_DIRS[@]} -eq 0 ]]; then
  warn "No patch or directories specified, skipping patch operation."
fi
