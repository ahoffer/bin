#!/bin/bash
set -euo pipefail

# Script to rebuild and deploy Docker images to k3s
# Usage: ./rebuild-and-deploy.sh [component...]
# Examples:
#   ./rebuild-and-deploy.sh                    # Build and deploy all
#   ./rebuild-and-deploy.sh graphql            # Build and deploy only graphql
#   ./rebuild-and-deploy.sh edge graphql docs  # Build and deploy specific components

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DEPLOY_SCRIPT="$SCRIPT_DIR/deploy-image.sh"
readonly PROJECT_ROOT="${CX_PROJECT_ROOT:-/projects/cx-search}"
readonly REGISTRY="registry.octo-cx-prod.runshiftup.com/octo-cx/cx/cx-search"
readonly VERSION="1.27.0-SNAPSHOT"

# Component name -> docker directory (image name = dir, deploy = cx-{dir minus cx- prefix})
declare -rA DIRS=([edge]=cx-edge [app]=app [graphql]=graphql [docs]=docs [redirect]=redirect [video-streaming]=video-streaming)

banner() {
  printf '\n========================================\n%s\n========================================\n' "$1"
}

build_component() {
  local name="$1"
  local dir="${DIRS[$name]}"
  local deploy="cx-${dir#cx-}"  # strip cx- if present, then add it back
  local image="$REGISTRY/$dir:$VERSION"

  banner "Building $name"
  (cd "$PROJECT_ROOT/docker/$dir" && mvn install -DskipTests)

  banner "Deploying $name ($image -> $deploy)"
  "$DEPLOY_SCRIPT" "$image" "$deploy"
}

# --- Main ---

if [[ ! -d "$PROJECT_ROOT/docker" ]]; then
  echo "Error: Project root not found at $PROJECT_ROOT"
  echo "Set CX_PROJECT_ROOT environment variable to your cx-search directory"
  exit 1
fi

targets=("${@:-${!DIRS[@]}}")  # use args, or all keys if no args

for target in "${targets[@]}"; do
  [[ -v DIRS[$target] ]] || { echo "Error: Unknown component '$target'. Valid: ${!DIRS[*]}"; exit 1; }
done

echo "Will build and deploy: ${targets[*]}"

for target in "${targets[@]}"; do
  build_component "$target"
done

banner "All done!"
