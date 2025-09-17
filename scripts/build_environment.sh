#!/bin/bash

######################################
# Usage
######################################
usage() {
  info "Usage: $0 [options]"
  echo ""
  echo "This script downloads and configures everything needed to run a <backend> in a <target> machine."
  echo ""
  echo "Options:"
  echo "  -t, --target   Target platform"
  echo "  -b, --backend  Backend name"
  echo "  -s, --skip     Skip GIT cloning"
  echo "  -v, --verbose  Verbose output"
  echo "  -h, --help     Show this help and exit"
  echo ""
  warn "Valid <target>-<backend>:"
  cat "${ENVIRONMENTS_LIST}"
  exit 1
}

######################################
# Command runner
######################################
run_cmd() {
  local logfile=$1; shift
  if [[ $VERBOSE -eq 1 ]]; then
    "$@" 2>&1 | tee -a "$logfile"
  else
    "$@" &>> "$logfile"
  fi
}

######################################
# Repo cloning
######################################
clone_repo() {
  local name=$1
  local lname=${name,,}
  local build_flag_var="${name}_BUILD"
  local repo_var="${name}_REPOSITORY"
  local branch_var="${name}_BRANCH"
  local commit_var="${name}_COMMIT"
  local dir_var="${lname}_dir"

  local build_flag="${!build_flag_var:-}"
  local repo="${!repo_var:-}"
  local branch="${!branch_var:-}"
  local commit="${!commit_var:-}"
  local dir="${!dir_var:-}"
  local log_file="${log_dir}/${lname}_clone.log"

  [[ ${build_flag,,} != y && ${build_flag,,} != yes ]] && return 0

  info "Cloning $name repository..."
  if [[ -n "$commit" ]]; then
    run_cmd "$log_file" git clone "$repo" "$dir" || return 1
    run_cmd "$log_file" git -C "$dir" reset --hard "$commit" || return 2
    success "$name cloned at commit $commit"
  elif [[ -n "$branch" ]]; then
    run_cmd "$log_file" git clone --depth 1 --branch "$branch" "$repo" "$dir" || return 1
    success "$name cloned from branch $branch"
  else
    run_cmd "$log_file" git clone "$repo" "$dir" || return 1
    success "$name cloned from master"
  fi
}

######################################
# Compilation
######################################
compile_component() {
  local name=$1
  local build_flag_var="${name}_BUILD"
  local build_flag="${!build_flag_var:-}"

  [[ ${build_flag,,} != y && ${build_flag,,} != yes ]] && return 0

  local patch_args_var="${name}_PATCH_ARGS"
  local upd_args_var="UPD_${name}_COMPILE_ARGS"
  local compile_args_var="${name}_COMPILE_ARGS"

  local patch_args="${!patch_args_var}"
  local upd_args="${!upd_args_var}"
  local compile_args="${!compile_args_var}"
  local log_file="${log_dir}/${name,,}_compile.log"


  : > "$log_file"
  info "Compiling $name"

  if [[ -f "${script_dir}/patch/${name,,}_patch.sh" ]]; then
    info "  Patching $name"
  run_cmd "$log_file" bash -c "yes n | '${script_dir}/patch/${name,,}_patch.sh' -t $TARGET -b $BACKEND $patch_args" \
      || { error "$name patching failed (see $log_file)"; exit 1; }
  fi

  if [[ -f "${script_dir}/defconfigs/${name,,}_update_defconfigs.sh" ]]; then
    info "  Updating $name configuration"
    run_cmd "$log_file" bash -c "yes y | '${script_dir}/defconfigs/${name,,}_update_defconfigs.sh' -t $TARGET -b $BACKEND $upd_args" \
      || { error "$name defconfig update failed (see $log_file)"; exit 1; }
  fi

  if [[ -f "${script_dir}/compile/${name,,}_compile.sh" ]]; then
    info "  Building $name"
    if run_cmd "$log_file" bash -c "yes y | '${script_dir}/compile/${name,,}_compile.sh' -t $TARGET -b $BACKEND $compile_args"; then
      success "$name compiled successfully"
    else
      error "$name compilation failed (see $log_file)"
      exit 1
    fi
  else
    error "No compile script found for $name"
    exit 1
  fi
}

######################################
# Main
######################################
script_dir=$(dirname -- "$(readlink -f -- "$0")")
source "${script_dir}/common/common.sh"
log_dir=$(realpath -m "${script_dir}/../log")

SKIPCLONE=0
VERBOSE=0
TARGET=""
BACKEND=""

# Parse args (short + long options)
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target)   TARGET="$2"; shift 2 ;;
    -b|--backend)  BACKEND="$2"; shift 2 ;;
    -s|--skip)     SKIPCLONE=1; shift ;;
    -v|--verbose)  VERBOSE=1; shift ;;
    -h|--help)     usage ;;
    *)             usage ;;
  esac
done

source "${script_dir}/common/set_environment.sh" "${TARGET}" "${BACKEND}"

# Create dirs
mkdir -p "${build_dir}" "${install_dir}" "${output_dir}" \
         "${boot_dir}" "${boot_sources_dir}" \
         "${rootfs_dir}" "${rootfs_dir}/${TARGET}" "${log_dir}"
rm -f "${log_dir}"/*

######################################
# Clone phase
######################################
info "### CLONE PHASE ###"
if [[ $SKIPCLONE -eq 0 ]]; then
  while read -r comp; do
    [[ -z "$comp" || "$comp" =~ ^# ]] && continue
    if ! clone_repo "$comp"; then
      error "Failed to clone $comp (see ${log_dir}/${comp,,}_clone.log)"
      exit 1
    fi
  done < "${environment_dir}/components.txt"
else
  warn "Skipping clone from GIT repositories"
fi
echo ""

######################################
# Compile phase
######################################
info "### COMPILING PHASE ###"
while read -r comp; do
  [[ -z "$comp" || "$comp" =~ ^# ]] && continue
  compile_component "$comp"
done < "${environment_dir}/components.txt"

success "Build finished successfully!"