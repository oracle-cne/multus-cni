#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

EXPECTED_BINARIES_STRING="${EXPECTED_BINARIES:-/opt/cni/bin/ptp /opt/cni/bin/portmap /opt/cni/bin/tuning}"
EXPECTED_CNI_DIR="${EXPECTED_CNI_DIR:-/etc/cni/net.d}"
TEST_POD_NAME="sysctl-modified"

read -r -a EXPECTED_BINARIES <<< "${EXPECTED_BINARIES_STRING}"

trap cleanup_e2e_helpers EXIT

check_host_binaries() {
    local node_name="$1"
    local host_binary

    log "Inspecting host CNI state on node ${node_name}"
    exec_on_node "${node_name}" "ls -l /host/opt/cni/bin"
    exec_on_node "${node_name}" "ls -l /host${EXPECTED_CNI_DIR}"

    for host_binary in "${EXPECTED_BINARIES[@]}"; do
        log "Checking ${host_binary} on node ${node_name}"
        exec_on_node "${node_name}" "test -f /host${host_binary}" || fail "missing ${host_binary} on node ${node_name}"
    done
}

log "Preparing environment for the passthrough chaining test"
prepare_basic_environment
generate_manifests

log "Applying the passthrough Multus configuration update"
kubectl apply -f "${SCRIPT_DIR}/yamls/subdirectory-chain-passthru-configupdate.yml"
log "Restarting the Multus DaemonSet"
kubectl rollout restart daemonset/kube-multus-ds-amd64 -n kube-system
kubectl rollout status daemonset/kube-multus-ds-amd64 -n kube-system --timeout=300s

check_host_binaries "${TARGET_NODE_1}"
if [[ "${TARGET_NODE_2}" != "${TARGET_NODE_1}" ]]; then
    check_host_binaries "${TARGET_NODE_2}"
fi

log "Applying the passthrough chaining DaemonSet"
kubectl apply -f "${SCRIPT_DIR}/yamls/subdirectory-chaining-passthru.yml"
kubectl rollout status daemonset/cni-setup-daemonset --timeout=300s

log "Creating the passthrough validation pod"
kubectl apply -f "${SCRIPT_DIR}/yamls/subdirectory-chaining-pod.yml"
kubectl wait --for=condition=Ready "pod/${TEST_POD_NAME}" --timeout=300s

log "Checking sysctl net.ipv4.conf.eth0.arp_filter"
SYSCTL_VALUE="$(kubectl exec "${TEST_POD_NAME}" -- sysctl -n net.ipv4.conf.eth0.arp_filter)"
if [[ "${SYSCTL_VALUE}" != "1" ]]; then
    fail "net.ipv4.conf.eth0.arp_filter is ${SYSCTL_VALUE}, expected 1"
fi

log "Cleaning up passthrough chaining test resources"
kubectl delete -f "${SCRIPT_DIR}/yamls/subdirectory-chaining-pod.yml"
kubectl delete -f "${SCRIPT_DIR}/yamls/subdirectory-chaining-passthru.yml"
