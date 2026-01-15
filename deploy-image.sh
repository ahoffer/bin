#!/bin/bash
set -euo pipefail

readonly IMAGE="${1:?Usage: $0 <image:tag> <deployment-name>}"
readonly DEPLOY_NAME="${2:?Usage: $0 <image:tag> <deployment-name>}"
readonly REMOTE_HOST="bigfish"
readonly NAMESPACE="octocx"
readonly RETRY_TIMEOUT=60
readonly RETRY_INTERVAL=2

get_pod_selector() {
  kubectl get deployment "$DEPLOY_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.selector.matchLabels}' |
    jq -r 'to_entries | map("\(.key)=\(.value)") | join(",")'
}

# Check for pod failure states that indicate deployment won't succeed
# Returns 1 and prints error if fatal condition found
check_pod_failures() {
  local selector="$1"
  local fatal_reasons="CrashLoopBackOff|ImagePullBackOff|ErrImagePull|CreateContainerConfigError|InvalidImageName"

  while read -r pod_name reason _; do
    [[ -z "$pod_name" ]] && continue
    if [[ "$reason" =~ ^($fatal_reasons)$ ]]; then
      echo "ERROR: Pod $pod_name is in $reason state"
      kubectl describe pod "$pod_name" -n "$NAMESPACE" | tail -20
      return 1
    fi
  done < <(kubectl get pod -n "$NAMESPACE" -l "$selector" \
    -o jsonpath='{range .items[*]}{.metadata.name} {.status.containerStatuses[0].state.waiting.reason}{"\n"}{end}')

  return 0
}

# Outputs status for each pod, returns 0 if all match expected hash
verify_pod_images() {
  local expected="$1" selector="$2" result=0

  while read -r pod_name pod_hash _; do
    [[ -z "$pod_name" ]] && continue
    if [[ "$pod_hash" == "$expected" ]]; then
      echo "✓ $pod_name"
    else
      printf "✗ %s\n  got:      %s\n  expected: %s\n" "$pod_name" "$pod_hash" "$expected"
      result=1
    fi
  done < <(kubectl get pod -n "$NAMESPACE" -l "$selector" \
    -o jsonpath='{range .items[*]}{.metadata.name} {.status.containerStatuses[0].imageID}{"\n"}{end}')

  return "$result"
}

echo "==> Exporting and importing image..."
docker save "$IMAGE" | ssh "$REMOTE_HOST" 'sudo k3s ctr images import -'

echo "==> Restarting deployment $DEPLOY_NAME..."
kubectl rollout restart deployment "$DEPLOY_NAME" -n "$NAMESPACE"

echo "==> Waiting for rollout..."
kubectl rollout status deployment "$DEPLOY_NAME" -n "$NAMESPACE" --timeout=120s

echo "==> Getting expected image hash..."
EXPECTED_HASH=$(ssh "$REMOTE_HOST" "sudo k3s crictl inspecti '$IMAGE' 2>/dev/null" | jq -r '.status.id')
: "${EXPECTED_HASH:?ERROR: Could not get image hash for $IMAGE}"
echo "Expected: $EXPECTED_HASH"

echo "==> Verifying pod images..."
SELECTOR=$(get_pod_selector)
SECONDS=0

while ! output=$(verify_pod_images "$EXPECTED_HASH" "$SELECTOR"); do
  ((SECONDS >= RETRY_TIMEOUT)) && { echo "$output"; echo "ERROR: Image verification failed after ${RETRY_TIMEOUT}s"; exit 1; }
  check_pod_failures "$SELECTOR" || exit 1
  echo "Pods not yet running expected image, retrying in ${RETRY_INTERVAL}s... (${SECONDS}s/${RETRY_TIMEOUT}s)"
  sleep "$RETRY_INTERVAL"
done

echo "$output"
echo "==> Done - all pods verified"
