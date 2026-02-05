#!/bin/bash
#
# Copyright (c) Octo Consulting Group
#
# <p>This is free software: you can redistribute it and/or modify it under the terms of the GNU
# Lesser General Public License as published by the Free Software Foundation, either version 3 of
# the License, or any later version.
#
# <p>This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details. A copy of the GNU Lesser General Public
# License is distributed along with this program and can be found at
# <http://www.gnu.org/licenses/lgpl.html>.
#

# ═══════════════════════════════════════════════════════════════════════════════
# devlocalk8s.sh - Local Development Server for CX Search Frontend
# ═══════════════════════════════════════════════════════════════════════════════
#
# PURPOSE:
#   Run the frontend locally on your workstation while connecting to backend
#   services running on a remote Kubernetes cluster (octocx).
#
# USAGE:
#   ./devlocalk8s.sh
#
# PREREQUISITES:
#   - Backend services running on octocx (K8s)
#   - Certificates generated in distributions/octocx/.../certs/
#   - next.config.local.js in the same directory as this script
#
# WHAT IT DOES:
#   1. Sets environment variables for localhost:3001 with octocx backends
#   2. Temporarily swaps next.config.js with next.config.local.js (adds rewrites)
#   3. Starts the Next.js dev server
#   4. Restores original next.config.js on exit (Ctrl+C)
#
# WHY REWRITES?
#   Browser security (CORS) blocks direct requests from localhost to octocx.
#   Next.js rewrites proxy requests server-side, avoiding CORS:
#     localhost:3001/graphql  →  octocx/graphql
#     localhost:3001/geoserver → octocx/geoserver
#     etc.
#
# WHY NODE_EXTRA_CA_CERTS?
#   Next.js rewrites don't respect NODE_TLS_REJECT_UNAUTHORIZED (known bug).
#   We must provide the CA cert that signed octocx's certificates.
#
# FILES:
#   devlocalk8s.sh        - This script
#   next.config.local.js  - Next.js config with rewrite rules (standalone copy)
#
# ═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(dirname "$0")"
cd "$SCRIPT_DIR"

# ─── Environment ───────────────────────────────────────────────────────────────
export NODE_TLS_REJECT_UNAUTHORIZED=0  # Accept self-signed certs from octocx
export NODE_EXTRA_CA_CERTS=../../distributions/octocx/cx-helm-chart/src/main/helm/local-only/config/certs/CA/ca.crt
export VERSION='dev-version'
export PROTOCOL=https
export HOSTNAME=localhost
export PORT=3001
export SITE=https://localhost:3001
export NEXTAUTH_URL=https://localhost:3001
export NEXTAUTH_URL_INTERNAL=https://localhost:3001

# Backend services - proxied through Next.js rewrites (avoids CORS)
export IDP_BASE_URL=https://octocx
export IDP_REDIRECT_URL=https://octocx
export GRAPHQL_BASE_URL=https://localhost:3001/graphql
export GEOSERVER_BASE_URL=https://localhost:3001/geoserver
export NODE_BASE_URL=https://octocx/endpoint
export TILE_SERVER_ZYX_URL=https://localhost:3001/tile-proxy/tilesZYX
export TILE_SERVER_ZXY_URL=https://localhost:3001/tile-proxy/tilesZXY
export DOCUMENTATION_SERVER=https://localhost:3001/docs
export STREAM_SERVER_HOST=octocx
export STREAM_ABR_ENABLED=false
export STREAM_SERVER_LLHLS_ENABLED=true
export STREAM_SERVER_WEBRTC_ENABLED=true
export STREAM_SERVER_WEBRTC_PORT=443
export STREAM_SERVER_LLHLS_PORT=443
export TRANSFER_BASE_URL=https://localhost:3001/transfer
export AITR_BASE_URL=http://octocx:5005/AiTR/v6
export AITR_MAX_VLM_STREAMS=1
export ONE_SHOT_BASE_URL=http://octocx:5005/OneShot/v1
export SEMANTIC_EDGE_URL=http://octocx:3000

# Features
export FEATURE_FLAGS=sa,video,tak,aitr,vlm,trackingProfile,charts,missionSets
export DEPLOYMENT_TYPE=edge
export OVENPLAYER_DEBUG=false
export USE_CUSTOM_BRANDING=false
export LOWEST_SYSTEM_CLASSIFICATION=UNCLASSIFIED
export APP_TYPE=cx

# Auth
export NEXTAUTH_SECRET=sibMqulWRf1Us/OF09WAkMixJAWMLIgijNEbS8t+GQM=

# Certificates (from octocx distro - localhost is in SAN)
export KEY_PATH=../../distributions/octocx/cx-helm-chart/src/main/helm/local-only/config/certs/output/octocx/server.key
export CERT_PATH=../../distributions/octocx/cx-helm-chart/src/main/helm/local-only/config/certs/output/octocx/server.crt

# ─── Swap next.config.js ───────────────────────────────────────────────────────
cp next.config.js next.config.js.bak
cp next.config.local.js next.config.js

cleanup() {
    echo "Restoring next.config.js..."
    mv next.config.js.bak next.config.js
}
trap cleanup EXIT

# ─── Run ───────────────────────────────────────────────────────────────────────
yarn cross-env NODE_ENV=development node src/server.js
