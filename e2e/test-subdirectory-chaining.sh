#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

trap cleanup_e2e_helpers EXIT

log "Preparing environment for the subdirectory chaining test"
prepare_basic_environment
discover_default_network_name
generate_manifests

log "Applying the chaining DaemonSet manifest"
kubectl apply -f "${SCRIPT_DIR}/yamls/subdirectory-chaining.yml"
log "Waiting for the chaining DaemonSet rollout to complete"
kubectl rollout status daemonset/cni-setup-daemonset --timeout=300s

log "Creating the sysctl verification pod"
kubectl apply -f "${SCRIPT_DIR}/yamls/subdirectory-chaining-pod.yml"
log "Waiting for the sysctl verification pod to become Ready"
kubectl wait --for=condition=Ready pod/sysctl-modified --timeout=300s

log "Checking sysctl net.ipv4.conf.eth0.arp_filter"
SYSCTL_VALUE="$(kubectl exec sysctl-modified -- sysctl -n net.ipv4.conf.eth0.arp_filter)"
if [[ "${SYSCTL_VALUE}" != "1" ]]; then
    fail "net.ipv4.conf.eth0.arp_filter is ${SYSCTL_VALUE}, expected 1"
fi

log "Cleaning up chaining test resources"
kubectl delete -f "${SCRIPT_DIR}/yamls/subdirectory-chaining-pod.yml"
kubectl delete -f "${SCRIPT_DIR}/yamls/subdirectory-chaining.yml"
