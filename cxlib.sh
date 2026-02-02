#!/bin/bash
# Shared utilities for cx* scripts
#
# Source this file: source cxlib.sh

# ─────────────────────────────────────────────────────────────
# Timing
# ─────────────────────────────────────────────────────────────

_TIMER_START=""
_PHASE_START=""

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
  local end=$(date +%s)
  _format_elapsed $((end - _TIMER_START))
}

timer_end() {
  local label="${1:-Completed}"
  echo "==> $label in $(timer_elapsed)"
}

# Phase timing for use within phases
phase_timer_start() {
  _PHASE_START=$(date +%s)
}

phase_timer_elapsed() {
  local end=$(date +%s)
  _format_elapsed $((end - _PHASE_START))
}

# ─────────────────────────────────────────────────────────────
# Phase headers
# ─────────────────────────────────────────────────────────────

# Print a phase header
# Usage: phase_header "1/4" "Building source code"
phase_header() {
  local phase_num="$1"
  local title="$2"
  echo
  echo "========================================"
  echo "Phase ${phase_num}: ${title}"
  echo "========================================"
  phase_timer_start
}

# Print phase completion with timing
# Usage: phase_done "3/4"
phase_done() {
  local phase_num="$1"
  echo "    Phase ${phase_num} completed in $(phase_timer_elapsed)"
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
    echo "ERROR: Not in a project directory (no pom.xml found)" >&2
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
    echo "ERROR: Another $lock_name is running for this project" >&2
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

# Run maven build in a directory
# Usage: mvn_build <dir> [name]
mvn_build() {
  local dir="$1"
  local name="${2:-$dir}"
  local logfile="/tmp/cxbuild-mvn-${name}.log"
  local start=$(date +%s)
  [[ -d "$dir" ]] || { echo "Error: Directory not found: $dir" >&2; return 1; }
  echo "==> Maven build: $name -> $logfile"
  (cd "$dir" && mvn clean install -DskipTests -T6) > "$logfile" 2>&1
  local status=$?
  local elapsed=$(($(date +%s) - start))
  local time_str
  time_str=$(_format_elapsed $elapsed)
  [[ $status -eq 0 ]] && echo "    [OK] $name ($time_str)" || echo "    [FAIL] $name ($time_str) - see $logfile"
  return $status
}

# ─────────────────────────────────────────────────────────────
# Parallel job execution
# ─────────────────────────────────────────────────────────────

# Global associative arrays for job tracking
declare -gA _JOB_PIDS=()
declare -ga _JOB_FAILURES=()

# Clear job tracking state
jobs_init() {
  _JOB_PIDS=()
}

# Start a background job with logging
# Usage: job_start <name> <logfile> <command...>
job_start() {
  local name="$1"
  local logfile="$2"
  shift 2
  (
    "$@" > "$logfile" 2>&1
    local status=$?
    [[ $status -eq 0 ]] && echo "[OK] $name" || echo "[FAIL] $name - see $logfile"
    exit $status
  ) &
  _JOB_PIDS[$name]=$!
}

# Wait for all jobs and collect failures into provided array
# Usage: jobs_wait failures_array
jobs_wait() {
  local -n failures_ref=$1
  local prefix="${2:-job}"
  for name in "${!_JOB_PIDS[@]}"; do
    wait "${_JOB_PIDS[$name]}" || failures_ref+=("${prefix}:$name")
  done
}

# Run a command in subshell with logging, print [OK]/[FAIL]
# Usage: run_logged <name> <logfile> <command...>
# Returns: exit status of command
run_logged() {
  local name="$1"
  local logfile="$2"
  shift 2
  "$@" > "$logfile" 2>&1
  local status=$?
  [[ $status -eq 0 ]] && echo "[OK] $name" || echo "[FAIL] $name - see $logfile"
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
  local ts=$(date +%Y%m%d-%H%M%S)
  if [[ -n "$suffix" ]]; then
    echo "/tmp/${prefix}-${suffix}-${ts}.log"
  else
    echo "/tmp/${prefix}-${ts}.log"
  fi
}

# Generate simple log file path without timestamp
# Usage: logfile_simple <prefix> <suffix>
logfile_simple() {
  local prefix="$1"
  local suffix="$2"
  echo "/tmp/${prefix}-${suffix}.log"
}
