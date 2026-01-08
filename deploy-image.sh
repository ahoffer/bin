#!/bin/bash
set -e

IMAGE="$1"
DEPLOY_NAME="$2"
REMOTE_HOST="bigfish"

if [ -z "$IMAGE" ] || [ -z "$DEPLOY_NAME" ]; then
  echo "Usage: $0 <image:tag> <deployment-name>"
  exit 1
fi

echo "==> Exporting and importing image..."
docker save "$IMAGE" | ssh "$REMOTE_HOST" 'sudo k3s ctr images import -'

echo "==> Restarting deployment $DEPLOY_NAME..."
kubectl rollout restart deployment "$DEPLOY_NAME" -n octocx

echo "==> Waiting for rollout..."
kubectl rollout status deployment "$DEPLOY_NAME" -n octocx --timeout=120s

echo "==> Verifying pod image..."
kubectl get pod -n octocx -o jsonpath="{range .items[*]}{.metadata.name}{\" \"}{.status.containerStatuses[*].imageID}{\"\n\"}{end}" | grep "$DEPLOY_NAME"

echo "==> Done"
