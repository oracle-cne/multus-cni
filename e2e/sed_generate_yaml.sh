#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

CNI_VERSION="${CNI_VERSION:-0.4.0}"
E2E_POD_IMAGE="${E2E_POD_IMAGE:-container-registry.oracle.com/os/oraclelinux:8}"
MULTUS_IMAGE="${MULTUS_IMAGE:-container-registry.oracle.com/example/multus:e2e}"
TARGET_NODE_1="${TARGET_NODE_1:-worker-a}"
TARGET_NODE_2="${TARGET_NODE_2:-worker-b}"
STATIC_POD_NODE="${STATIC_POD_NODE:-control-plane-a}"
MACVLAN_MASTER_INTERFACE="${MACVLAN_MASTER_INTERFACE:-eth1}"
DEFAULT_NETWORK_CNI_NAME="${DEFAULT_NETWORK_CNI_NAME:-primary-cni}"
DRA_DEVICE_CLASS_NAME="${DRA_DEVICE_CLASS_NAME:-gpu.example.com}"

templates_dir="$(dirname "$(readlink -f "$0")")/templates"
output_dir="$(dirname "$(readlink -f "$0")")/yamls"

if [[ ! -d "${output_dir}" ]]; then
    mkdir "${output_dir}"
fi

escape_sed() {
    printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

for template_file in "${templates_dir}"/*.j2; do
    output_file="${output_dir}/$(basename "${template_file%.j2}")"
    echo "Processing ${template_file} -> ${output_file}"
    sed \
        -e "s/{{ CNI_VERSION }}/$(escape_sed "${CNI_VERSION}")/g" \
        -e "s/{{ E2E_POD_IMAGE }}/$(escape_sed "${E2E_POD_IMAGE}")/g" \
        -e "s/{{ MULTUS_IMAGE }}/$(escape_sed "${MULTUS_IMAGE}")/g" \
        -e "s/{{ TARGET_NODE_1 }}/$(escape_sed "${TARGET_NODE_1}")/g" \
        -e "s/{{ TARGET_NODE_2 }}/$(escape_sed "${TARGET_NODE_2}")/g" \
        -e "s/{{ STATIC_POD_NODE }}/$(escape_sed "${STATIC_POD_NODE}")/g" \
        -e "s/{{ MACVLAN_MASTER_INTERFACE }}/$(escape_sed "${MACVLAN_MASTER_INTERFACE}")/g" \
        -e "s/{{ DEFAULT_NETWORK_CNI_NAME }}/$(escape_sed "${DEFAULT_NETWORK_CNI_NAME}")/g" \
        -e "s/{{ DRA_DEVICE_CLASS_NAME }}/$(escape_sed "${DRA_DEVICE_CLASS_NAME}")/g" \
        "${template_file}" > "${output_file}"
done
