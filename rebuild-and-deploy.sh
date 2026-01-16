#!/bin/bash
set -euo pipefail

# Kill child processes on exit
trap 'pkill -P $$ 2>/dev/null || true' EXIT

# Build and deploy cx-search components to k3s
# Usage: rebuild-and-deploy.sh [-p project_root] [component...]
# Examples:
#   rebuild-and-deploy.sh                           # Build and deploy all
#   rebuild-and-deploy.sh graphql                   # Build and deploy only graphql
#   rebuild-and-deploy.sh edge graphql docs         # Build and deploy specific components
#   rebuild-and-deploy.sh -p /builds/cx-search app  # Use alternate project root

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  sed -n '4,10p' "$0"
  echo -e "\nComponents: $("$SCRIPT_DIR/cx-config" components | tr '\n' ' ')"
  exit 0
}

project_root="${CX_PROJECT_ROOT:-/projects/cx-search}"
while [[ $# -gt 0 && "$1" == -* ]]; do
  case "$1" in
    -h|--help) usage ;;
    -p|--project) project_root="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done
readonly PROJECT_ROOT="$project_root"

if [[ ! -d "$PROJECT_ROOT/docker" ]]; then
  echo "Error: Project root not found at $PROJECT_ROOT" >&2
  echo "Set CX_PROJECT_ROOT or use -p <path>" >&2
  exit 1
fi

# Get targets: args or all components
if [[ $# -gt 0 ]]; then
  targets=("$@")
else
  mapfile -t targets < <("$SCRIPT_DIR/cx-config" components)
fi

# Validate targets
for target in "${targets[@]}"; do
  "$SCRIPT_DIR/cx-config" dir "$target" >/dev/null  # exits if invalid
done

echo "Will build and deploy: ${targets[*]}"
echo

for target in "${targets[@]}"; do
  echo "========================================"
  echo " $target"
  echo "========================================"
  "$SCRIPT_DIR/cx-build" -p "$PROJECT_ROOT" "$target"
  "$SCRIPT_DIR/cx-deploy" "$target"
  echo
done

echo "========================================"
echo " All done!"
echo "========================================"
