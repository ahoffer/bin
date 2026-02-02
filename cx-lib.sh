#!/bin/bash
# Shared utilities for cx* scripts
#
# Source this file: source cx-lib.sh

# Find project root by walking up looking for pom.xml (like git does)
# Returns the topmost directory containing pom.xml, or empty string if none found
cx_find_project_root() {
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
# Usage: cx_require_project_root
# Sets CX_PROJECT_ROOT variable on success
cx_require_project_root() {
  CX_PROJECT_ROOT=$(cx_find_project_root)
  if [[ -z "$CX_PROJECT_ROOT" ]]; then
    echo "ERROR: Not in a project directory (no pom.xml found)" >&2
    echo "Run this command from a project root or subdirectory" >&2
    exit 1
  fi
}

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

# List components as space-separated string
# Returns empty string if not in a project directory
# Usage: cx_list_components
cx_list_components() {
  cxconfig components 2>/dev/null | tr '\n' ' '
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
