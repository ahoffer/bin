#!/bin/bash
# Shared utilities for cx* scripts
#
# Source this file: source cx-lib.sh

# Run maven build in a directory
# Usage: cx_mvn_build <dir> [name]
# Logs written to /tmp/cxbuild-mvn-<name>.log
cx_mvn_build() {
  local dir="$1"
  local name="${2:-$dir}"
  local logfile="/tmp/cxbuild-mvn-${name}.log"
  [[ -d "$dir" ]] || { echo "Error: Directory not found: $dir" >&2; return 1; }
  echo "==> Maven build: $name -> $logfile"
  (cd "$dir" && mvn clean install -DskipTests -T6) > "$logfile" 2>&1
  local status=$?
  [[ $status -eq 0 ]] && echo "    [OK] $name" || echo "    [FAIL] $name - see $logfile"
  return $status
}

# Build cxconfig args array from app value
# Usage: local -a cfg_args; cx_cfg_args cfg_args "$app"
cx_cfg_args() {
  local -n arr=$1
  local app_value="${2:-}"
  arr=()
  [[ -n "$app_value" ]] && arr+=(-a "$app_value")
}

# List components as space-separated string
# Usage: cx_list_components [app]
cx_list_components() {
  local app_flag=""
  [[ -n "${1:-}" ]] && app_flag="-a $1"
  cxconfig $app_flag components | tr '\n' ' '
}

# Validate component exists
# Usage: cx_valid_component <component> <all_components_array_name>
cx_valid_component() {
  local comp="$1"
  local -n all_comps=$2
  local known
  for known in "${all_comps[@]}"; do
    [[ "$comp" == "$known" ]] && return 0
  done
  return 1
}
