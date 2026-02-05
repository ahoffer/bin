#!/bin/bash
set -euo pipefail

# Kill child processes on exit
trap 'pkill -P $$ 2>/dev/null || true' EXIT

# Deploy a Docker image to k3s: push, restart, and verify
# Usage: deploy-image.sh [-r host] [-n namespace] [-t timeout] <image:tag> [deployment]
# Examples:
#   deploy-image.sh myapp:1.0 cx-app
#   deploy-image.sh -r node2 myapp:1.0 cx-app
#   deploy-image.sh -n prod -t 180 myapp:1.0 cx-app

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  sed -n '4,8p' "$0"
  echo
  echo "If deployment is omitted, it defaults to the image name (before the tag)."
  exit 0
}

remote_host="bigfish"
namespace="octocx"
timeout=60
quiet=false
while [[ $# -gt 0 && "$1" == -* ]]; do
  case "$1" in
    -h|--help) usage ;;
    -q|--quiet) quiet=true; shift ;;
    -r|--remote) remote_host="$2"; shift 2 ;;
    -n|--namespace) namespace="$2"; shift 2 ;;
    -t|--timeout) timeout="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

q_flag=""
$quiet && q_flag="-q"

readonly IMAGE="${1:?Usage: deploy-image.sh [-r host] [-n namespace] <image:tag> [deployment]}"
if [[ -n "${2:-}" ]]; then
  DEPLOY="$2"
else
  DEPLOY="${IMAGE%%:*}"
  DEPLOY="${DEPLOY##*/}"
fi

# Push image to remote k3s node
"$SCRIPT_DIR/k3s-push-image" $q_flag -H "$remote_host" "$IMAGE"

# Restart deployment and wait for rollout
"$SCRIPT_DIR/k8s-restart-deploy" $q_flag -n "$namespace" -t "${timeout}s" "$DEPLOY"

# Verify pods are running the correct image
"$SCRIPT_DIR/k8s-verify-image" $q_flag -n "$namespace" -r "$remote_host" -t "$timeout" "$IMAGE" "$DEPLOY"

$quiet || echo "==> Deploy complete"
