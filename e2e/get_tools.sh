#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

declare -A PACKAGE_BY_COMMAND=(
    [kubectl]="kubectl"
    [jq]="jq"
    [sed]="sed"
    [helm]="helm"
    [podman]="podman"
    [skopeo]="skopeo"
)

REQUIRED_COMMANDS=(kubectl jq sed)
OPTIONAL_COMMANDS=(helm podman skopeo)
missing_required=()
missing_optional=()

log() {
    printf '[multus-e2e-tools] %s\n' "$*"
}

check_command_set() {
    local target_array_name="$1"
    shift
    local command_name
    for command_name in "$@"; do
        if ! command -v "${command_name}" >/dev/null 2>&1; then
            if [[ "${target_array_name}" == "required" ]]; then
                missing_required+=("${command_name}")
            else
                missing_optional+=("${command_name}")
            fi
        fi
    done
}

print_packages() {
    local label="$1"
    shift
    local command_name
    local packages=()
    for command_name in "$@"; do
        packages+=("${PACKAGE_BY_COMMAND[${command_name}]}")
    done
    log "${label}: ${packages[*]}"
}

log "Checking required tools for the e2e suite"
check_command_set required "${REQUIRED_COMMANDS[@]}"
check_command_set optional "${OPTIONAL_COMMANDS[@]}"

if ((${#missing_required[@]} > 0)); then
    log "Missing required tools: ${missing_required[*]}"
    print_packages "Install the required dnf packages" "${missing_required[@]}"
fi

if ((${#missing_optional[@]} > 0)); then
    log "Missing optional tools: ${missing_optional[*]}"
    print_packages "Install optional dnf packages when needed" "${missing_optional[@]}"
fi

if ((${#missing_required[@]} > 0)); then
    exit 1
fi

log "Required tools are available"
