#!/bin/bash

usage() {
  cat <<EOF
$(basename "$0") - Delete builds and output for a target

Usage:
  $0 -t <target> -b <backend>

Options:
  -t, --target <target>     Target board/platform
  -b, --backend <backend>   Backend (e.g. jailhouse)
  -h, --help                Show this help message
EOF
  exit 1
}

current_dir=$(dirname -- "$(readlink -f -- "$0")")
script_dir=$(dirname "$current_dir")
source "$script_dir/common/common.sh"

TARGET="" BACKEND=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target) TARGET="$2"; shift 2 ;;
    -b|--backend) BACKEND="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) error "Unknown option: $1"; usage ;;
  esac
done

[[ -z "$TARGET" || -z "$BACKEND" ]] && { error "Both target and backend required."; usage; }

source "$script_dir/common/set_environment.sh" "$TARGET" "$BACKEND"

read -r -p "Delete ${TARGET}/${BACKEND} builds? (y/N): " REPLY
if [[ "${REPLY,,}" =~ ^y(es)?$ ]]; then
  rm -rf "${build_dir:?}"/*
  success "Deleted builds for ${TARGET}/${BACKEND}."
else
  warn "Skipping delete."
fi
