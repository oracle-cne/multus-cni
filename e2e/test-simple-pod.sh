#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

trap cleanup_e2e_helpers EXIT

log "Preparing environment for the simple pod test"
prepare_basic_environment
generate_manifests

log "Creating the simple pod manifest"
kubectl apply -f "${SCRIPT_DIR}/yamls/simple-pod.yml"
log "Waiting for the simple pod to become Ready"
kubectl wait --for=condition=Ready -l app=simple pod --timeout=300s

log "Cleaning up the simple pod manifest"
kubectl delete -f "${SCRIPT_DIR}/yamls/simple-pod.yml"
