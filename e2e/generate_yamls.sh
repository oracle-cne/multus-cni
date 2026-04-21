#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

echo "Generating manifests via sed_generate_yaml.sh"
"$(dirname "$(readlink -f "$0")")/sed_generate_yaml.sh"
