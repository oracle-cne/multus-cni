#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

log() {
    printf '[multus-e2e] %s\n' "$*"
}

log "Removing Multus e2e resources from the current cluster"
kubectl delete --ignore-not-found -f "${SCRIPT_DIR}/yamls/cni-install.yml"
kubectl delete --ignore-not-found -f "${SCRIPT_DIR}/yamls/multus-daemonset.yml"
kubectl delete --ignore-not-found -f "${SCRIPT_DIR}/yamls/multus-daemonset-thick.yml"

log "Teardown completed"
