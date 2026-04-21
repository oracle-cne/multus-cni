#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

trap cleanup_e2e_helpers EXIT

assert_pod_ip() {
    local pod_name="$1"
    local expected_ip="$2"
    local actual_ip

    log "Checking interface net1 on pod ${pod_name}"
    kubectl exec "${pod_name}" -- ip a show dev net1 >/dev/null

    actual_ip="$(kubectl exec "${pod_name}" -- ip -j a show | jq -r '.[] | select(.ifname == "net1") | .addr_info[] | select(.family == "inet") | .local')"
    if [[ "${actual_ip}" != "${expected_ip}" ]]; then
        fail "pod ${pod_name} has net1 address ${actual_ip}, expected ${expected_ip}"
    fi
    log "Verified ${pod_name} net1 address ${actual_ip}"
}

log "Preparing environment for the macvlan test"
prepare_e2e_environment

log "Applying the macvlan e2e manifest"
kubectl apply -f "${SCRIPT_DIR}/yamls/simple-macvlan1.yml"
log "Waiting for the macvlan pods to become Ready"
kubectl wait --for=condition=Ready -l app=macvlan pod --timeout=300s

assert_pod_ip "macvlan1-worker1" "10.1.1.11"
assert_pod_ip "macvlan1-worker2" "10.1.1.12"

log "Cleaning up the macvlan e2e manifest"
kubectl delete -f "${SCRIPT_DIR}/yamls/simple-macvlan1.yml"
