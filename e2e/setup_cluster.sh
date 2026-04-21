#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

MULTUS_MANIFEST="${MULTUS_MANIFEST:-multus-daemonset-thick.yml}"

trap cleanup_e2e_helpers EXIT

log "Starting cluster preparation for the Multus e2e suite"
require_commands kubectl jq sed
require_multus_image
prepare_e2e_environment

log "Applying Multus manifest yamls/${MULTUS_MANIFEST}"
kubectl apply -f "${SCRIPT_DIR}/yamls/${MULTUS_MANIFEST}"
log "Waiting for the Multus DaemonSet to become Ready"
kubectl -n kube-system rollout status daemonset/kube-multus-ds-amd64 --timeout=300s

log "Applying CNI plugin installation manifest"
kubectl apply -f "${SCRIPT_DIR}/yamls/cni-install.yml"
log "Waiting for the CNI plugin installation DaemonSet to become Ready"
kubectl -n kube-system rollout status daemonset/install-cni-plugins --timeout=400s

log "Cluster preparation completed"
