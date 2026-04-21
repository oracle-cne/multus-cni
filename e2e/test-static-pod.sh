#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

STATIC_MANIFEST_CONFIGMAP="multus-e2e-static-pod-manifest"
STATIC_HELPER_POD="multus-e2e-static-pod-helper"
STATIC_POD_FILE="/host/etc/kubernetes/manifests/static-web.yaml"

cleanup_static_pod_test() {
    log "Cleaning up static pod test resources"
    kubectl exec -n "${E2E_NAMESPACE}" "${STATIC_HELPER_POD}" -- /bin/bash -lc "rm -f ${STATIC_POD_FILE}" >/dev/null 2>&1 || true
    kubectl delete --ignore-not-found -n "${E2E_NAMESPACE}" pod/"${STATIC_HELPER_POD}" >/dev/null 2>&1 || true
    kubectl delete --ignore-not-found -n "${E2E_NAMESPACE}" configmap/"${STATIC_MANIFEST_CONFIGMAP}" >/dev/null 2>&1 || true
    kubectl delete --ignore-not-found -f "${SCRIPT_DIR}/static-pod-nad.yml" >/dev/null 2>&1 || true
}

trap 'cleanup_static_pod_test; cleanup_e2e_helpers' EXIT

log "Preparing environment for the static pod test"
prepare_basic_environment

log "Creating the NetworkAttachmentDefinition for the static pod"
kubectl apply -f "${SCRIPT_DIR}/static-pod-nad.yml"

log "Creating a ConfigMap with the static pod manifest payload"
kubectl create configmap "${STATIC_MANIFEST_CONFIGMAP}" \
    -n "${E2E_NAMESPACE}" \
    --from-file=static-web.yaml="${SCRIPT_DIR}/simple-static-pod.yml" \
    --dry-run=client -o yaml | kubectl apply -f -

log "Creating a helper pod on node ${STATIC_POD_NODE} to manage the static manifest path"
kubectl apply -f - >/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${STATIC_HELPER_POD}
  namespace: ${E2E_NAMESPACE}
spec:
  nodeName: ${STATIC_POD_NODE}
  hostNetwork: true
  tolerations:
  - operator: Exists
  containers:
  - name: helper
    image: ${E2E_POD_IMAGE}
    command:
    - /bin/bash
    - -lc
    - |
      set -euxo pipefail
      trap : TERM INT
      sleep infinity & wait
    securityContext:
      privileged: true
    volumeMounts:
    - name: host-manifests
      mountPath: /host/etc/kubernetes/manifests
    - name: manifest-payload
      mountPath: /payload
  volumes:
  - name: host-manifests
    hostPath:
      path: /etc/kubernetes/manifests
      type: DirectoryOrCreate
  - name: manifest-payload
    configMap:
      name: ${STATIC_MANIFEST_CONFIGMAP}
EOF
kubectl wait -n "${E2E_NAMESPACE}" --for=condition=Ready "pod/${STATIC_HELPER_POD}" --timeout=300s >/dev/null

log "Copying the static pod manifest onto node ${STATIC_POD_NODE}"
kubectl exec -n "${E2E_NAMESPACE}" "${STATIC_HELPER_POD}" -- /bin/bash -lc "cp /payload/static-web.yaml ${STATIC_POD_FILE}"

STATIC_POD_NAME="static-web-${STATIC_POD_NODE}"
log "Waiting for static pod ${STATIC_POD_NAME} to become Ready"
kubectl wait --for=condition=Ready "pod/${STATIC_POD_NAME}" --namespace=default --timeout=300s

log "Checking the static pod net1 interface"
kubectl exec "${STATIC_POD_NAME}" --namespace=default -- ip a show dev net1 >/dev/null
