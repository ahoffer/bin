#!/bin/bash
# Shared utilities for cx* scripts
#
# Source this file: source cxlib.sh

# ─────────────────────────────────────────────────────────────
# Terminal detection
# ─────────────────────────────────────────────────────────────

_IS_TTY=""
[[ -t 1 ]] && _IS_TTY=1
_C_RED=""
_C_RST=""
if [[ -n "$_IS_TTY" ]]; then
  _C_RED=$'\033[31m'
  _C_RST=$'\033[0m'
fi

# ─────────────────────────────────────────────────────────────
# Output helpers
# ─────────────────────────────────────────────────────────────

warn_msg() {
  echo "warning: $*"
}

err_msg() {
  echo "error: $*" >&2
}

# Print step name without newline so time can be appended when done.
_step_progress() {
  [[ -n "$_IS_TTY" ]] && printf "%s" "$1"
}

# Finish a step line. On tty, appends time to the name already printed
# by _step_progress. On non-tty, prints the full line.
_step_done() {
  local name="$1" time_str="$2" status="$3" logfile="${4:-}"
  if [[ -n "$_IS_TTY" ]]; then
    if [[ $status -eq 0 ]]; then
      printf " - %s\n" "$time_str"
    else
      printf " ${_C_RED}✗${_C_RST}\n"
      [[ -n "$logfile" ]] && echo "  ${logfile}"
    fi
  else
    if [[ $status -eq 0 ]]; then
      printf "%s - %s\n" "$name" "$time_str"
    else
      printf "%s FAILED\n" "$name"
      [[ -n "$logfile" ]] && echo "  ${logfile}"
    fi
  fi
}

# ─────────────────────────────────────────────────────────────
# Timing
# ─────────────────────────────────────────────────────────────

_TIMER_START=""

timer_start() {
  _TIMER_START=$(date +%s)
}

# Format seconds as "Xm Ys" or "Xs"
_format_elapsed() {
  local elapsed="$1"
  local min=$((elapsed / 60))
  local sec=$((elapsed % 60))
  if [[ $min -gt 0 ]]; then
    echo "${min}m ${sec}s"
  else
    echo "${sec}s"
  fi
}

timer_elapsed() {
  local end
  end=$(date +%s)
  _format_elapsed $((end - _TIMER_START))
}

# ─────────────────────────────────────────────────────────────
# Project detection
# ─────────────────────────────────────────────────────────────

# Find project root by walking up looking for pom.xml (like git does)
# Returns the topmost directory containing pom.xml, or empty string if none found
find_project_root() {
  local dir="$PWD"
  local last_with_pom=""
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/pom.xml" ]]; then
      last_with_pom="$dir"
    fi
    dir="$(dirname "$dir")"
  done
  echo "$last_with_pom"
}

# Require being in a project directory, exit with error if not
# Sets PROJECT_ROOT variable on success
require_project_root() {
  PROJECT_ROOT=$(find_project_root)
  if [[ -z "$PROJECT_ROOT" ]]; then
    err_msg "Not in a project directory (no pom.xml found)"
    echo "Run this command from a project root or subdirectory" >&2
    exit 1
  fi
}

# ─────────────────────────────────────────────────────────────
# Locking (prevent parallel builds)
# ─────────────────────────────────────────────────────────────

# Acquire exclusive lock for the current project
# Usage: acquire_lock [lock_name]
# Default lock_name is "build"
# Dies if another process holds the lock
acquire_lock() {
  local lock_name="${1:-build}"
  local project_hash
  project_hash=$(echo "$PROJECT_ROOT" | md5sum | cut -c1-8)
  local lock_file="/tmp/${lock_name}-${project_hash}.lock"

  exec 9>"$lock_file"

  if ! flock -n 9; then
    err_msg "Another $lock_name is running for this project"
    echo "Lock file: $lock_file" >&2
    exit 1
  fi
}

# ─────────────────────────────────────────────────────────────
# Component helpers
# ─────────────────────────────────────────────────────────────

# List components as space-separated string
list_components() {
  cxconfig components 2>/dev/null | tr '\n' ' '
}

# Validate component exists
# Usage: valid_component <component> <all_components_array_name>
valid_component() {
  local comp="$1"
  local -n all_comps=$2
  local known
  for known in "${all_comps[@]}"; do
    [[ "$comp" == "$known" ]] && return 0
  done
  return 1
}

# ─────────────────────────────────────────────────────────────
# Build helpers
# ─────────────────────────────────────────────────────────────

# Map components to Maven module paths, de-duplicated, in order.
# Usage: maven_modules_for_components components_array
maven_modules_for_components() {
  local -n comps=$1
  local -a modules=()
  local comp
  for comp in "${comps[@]}"; do
    case "$comp" in
      edge|redirect|video-streaming) modules+=("backend" "distributions") ;;
      graphql) modules+=("frontend/graphql") ;;
      app) modules+=("frontend/app") ;;
      docs) modules+=("docs") ;;
    esac
  done

  local -A seen=()
  local -a uniq=()
  local mod
  for mod in "${modules[@]}"; do
    [[ -n "${seen[$mod]:-}" ]] && continue
    seen[$mod]=1
    uniq+=("$mod")
  done

  printf '%s\n' "${uniq[@]}"
}

# Run maven build in a directory
# Usage: mvn_build <dir> [name]
mvn_build() {
  local dir="$1"
  local name="${2:-$dir}"
  local log_name
  log_name=$(basename "$name")
  local logfile="/tmp/cxbuild-mvn-${log_name}.log"
  local start
  start=$(date +%s)
  [[ -d "$dir" ]] || { err_msg "Directory not found: $dir"; return 1; }
  _step_progress "maven $name"
  (cd "$dir" && mvn clean install -DskipTests -T6) > "$logfile" 2>&1
  local status=$?
  local elapsed=$(($(date +%s) - start))
  local time_str
  time_str=$(_format_elapsed $elapsed)
  _step_done "maven $name" "$time_str" "$status" "$logfile"
  return $status
}

# Build all maven modules needed by the given components, deduplicated.
# Usage: build_maven_modules <project_root> <component...>
build_maven_modules() {
  local project_root="$1"
  shift
  local -a _bm_comps=("$@")
  local -a modules
  mapfile -t modules < <(maven_modules_for_components _bm_comps)
  for module in "${modules[@]}"; do
    mvn_build "$project_root/$module" "$project_root/$module" || return 1
  done
}

# Build docker image for a component
# Usage: docker_build <project_root> <component>
docker_build() {
  local project_root="$1"
  local component="$2"
  local docker_dir
  docker_dir=$(cxconfig dir "$component")
  [[ -d "$project_root/docker/$docker_dir" ]] || {
    err_msg "Directory not found: $project_root/docker/$docker_dir"
    return 1
  }
  local log_file
  log_file=$(logfile cxbuild "$docker_dir")
  run_logged "docker $project_root/docker/$docker_dir" "$log_file" \
    bash -c 'cd "$1" && mvn install -DskipTests' _ "$project_root/docker/$docker_dir"
}

# Deploy a component image to remote host
# Usage: deploy_component <component> <remote_host> <namespace>
deploy_component() {
  local component="$1"
  local remote_host="$2"
  local namespace="$3"
  local image deploy_name timeout
  image=$(cxconfig image "$component")
  deploy_name=$(cxconfig deploy "$component")
  timeout=$(cxconfig timeout "$component")
  local log_file
  log_file=$(logfile cxdeploy "$component")
  run_logged "deploy $component" "$log_file" \
    deployimage -q -r "$remote_host" -n "$namespace" -t "$timeout" "$image" "$deploy_name"
}

# Run a command with output redirected to logfile, showing name and elapsed
# time on completion. On failure, shows logfile path instead of time.
run_logged() {
  local name="$1"
  local logfile="$2"
  shift 2
  local start
  start=$(date +%s)
  _step_progress "$name"
  "$@" > "$logfile" 2>&1
  local status=$?
  local elapsed=$(($(date +%s) - start))
  local time_str
  time_str=$(_format_elapsed $elapsed)
  _step_done "$name" "$time_str" "$status" "$logfile"
  return $status
}

# ─────────────────────────────────────────────────────────────
# Log file helpers
# ─────────────────────────────────────────────────────────────

# Generate timestamped log file path
# Usage: logfile <prefix> [suffix]
# Example: logfile "cxbuild" "graphql" -> /tmp/cxbuild-graphql-20240102-153045.log
logfile() {
  local prefix="$1"
  local suffix="${2:-}"
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  if [[ -n "$suffix" ]]; then
    echo "/tmp/${prefix}-${suffix}-${ts}.log"
  else
    echo "/tmp/${prefix}-${ts}.log"
  fi
}
