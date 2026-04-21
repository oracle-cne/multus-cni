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

assert_route() {
    local pod_name="$1"
    local expected_gateway="$2"
    local actual_gateway

    actual_gateway="$(kubectl exec "${pod_name}" -- ip -j route | jq -r '.[] | select(.dst == "default") | .gateway')"
    if [[ "${actual_gateway}" != "${expected_gateway}" ]]; then
        fail "pod ${pod_name} has default gateway ${actual_gateway}, expected ${expected_gateway}"
    fi
    log "Verified ${pod_name} default gateway ${actual_gateway}"
}

assert_route_not_equal() {
    local pod_name="$1"
    local forbidden_gateway="$2"
    local actual_gateway

    actual_gateway="$(kubectl exec "${pod_name}" -- ip -j route | jq -r '.[] | select(.dst == "default") | .gateway')"
    if [[ -z "${actual_gateway}" ]]; then
        fail "pod ${pod_name} has no default route"
    fi
    if [[ "${actual_gateway}" == "${forbidden_gateway}" ]]; then
        fail "pod ${pod_name} unexpectedly switched its default route to ${actual_gateway}"
    fi
    log "Verified ${pod_name} retained its primary-network default gateway ${actual_gateway}"
}

log "Preparing environment for the default route test"
prepare_e2e_environment

log "Applying the default-route e2e manifest"
kubectl apply -f "${SCRIPT_DIR}/yamls/default-route1.yml"
log "Waiting for the default-route pods to become Ready"
kubectl wait --for=condition=Ready -l app=default-route1 pod --timeout=300s

assert_pod_ip "default-route-worker1" "10.1.1.21"
assert_route "default-route-worker1" "10.1.1.254"
assert_pod_ip "default-route-worker2" "10.1.1.22"
assert_route_not_equal "default-route-worker2" "10.1.1.254"

log "Cleaning up the default-route e2e manifest"
kubectl delete -f "${SCRIPT_DIR}/yamls/default-route1.yml"
