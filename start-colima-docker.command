#!/bin/bash
set -euo pipefail

PROFILE="default"
export DOCKER_HOST="unix://${HOME}/.colima/${PROFILE}/docker.sock"

echo "Starting Colima profile: ${PROFILE}"
colima start "${PROFILE}"
osascript -e 'display notification "Colima default started." with title "Start Colima"'
