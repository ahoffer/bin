#!/bin/bash
set -euo pipefail

PROFILE="default"

echo "Stopping Colima profile: ${PROFILE}"
colima stop "${PROFILE}"
osascript -e 'display notification "Colima default stopped." with title "Stop Colima"'
