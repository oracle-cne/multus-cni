#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

trap cleanup_e2e_helpers EXIT

log "Preparing environment for the DRA integration test"
prepare_basic_environment
generate_manifests

log "Checking that the DRA API is available"
kubectl get deviceclasses.resource.k8s.io >/dev/null

log "Checking that the required DRA DeviceClass ${DRA_DEVICE_CLASS_NAME} exists"
kubectl get "deviceclasses.resource.k8s.io/${DRA_DEVICE_CLASS_NAME}" >/dev/null || \
    fail "device class ${DRA_DEVICE_CLASS_NAME} is not installed; provision a DRA driver on the target cluster before running this test"

log "Creating the DRA integration pod manifest"
kubectl apply -f "${SCRIPT_DIR}/yamls/dra-integration.yml"
log "Waiting for the DRA integration pod to become Ready"
kubectl wait --for=condition=Ready -l app=dra-integration pod --timeout=300s

log "Checking for the DRA-injected environment variable"
env_variable="$(kubectl exec dra-integration -- /bin/bash -lc 'printf "%s" "${DRA_RESOURCE_DRIVER_NAME:-}"')"
if [[ "${env_variable}" != "${DRA_DEVICE_CLASS_NAME}" ]]; then
    fail "pod dra-integration reported DRA_RESOURCE_DRIVER_NAME=${env_variable}, expected ${DRA_DEVICE_CLASS_NAME}"
fi

log "Cleaning up the DRA integration manifest"
kubectl delete -f "${SCRIPT_DIR}/yamls/dra-integration.yml"
