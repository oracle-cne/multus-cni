## Multus e2e tests against an existing cluster

### Prerequisites

The e2e suite now targets an already running Kubernetes cluster.

Required tools:

- `kubectl`
- `jq`
- `sed`

Optional tools:

- `helm` for clusters where DRA components are managed separately
- `podman` and `skopeo` when building or mirroring an OCR-hosted `MULTUS_IMAGE`

Check the local toolchain with:

```bash
./get_tools.sh
```

### Required environment

Provide an OCR-hosted Multus image before running `setup_cluster.sh`:

```bash
export MULTUS_IMAGE=container-registry.oracle.com/your-tenant/multus:e2e
```

The suite discovers Ready nodes automatically. Override discovery only when the cluster requires explicit placement:

```bash
export TARGET_NODE_1=<node-name>
export TARGET_NODE_2=<node-name>
export STATIC_POD_NODE=<node-name>
export MACVLAN_MASTER_INTERFACE=<interface-name>
export DEFAULT_NETWORK_CNI_NAME=<primary-cni-name>
export DRA_DEVICE_CLASS_NAME=<device-class-name>
```

### Generate manifests

The test scripts regenerate `e2e/yamls/` using the current cluster settings:

```bash
./generate_yamls.sh
```

### Deploy Multus for e2e

```bash
./setup_cluster.sh
```

### Run tests

```bash
./test-simple-pod.sh
./test-simple-macvlan1.sh
./test-default-route1.sh
./test-subdirectory-chaining.sh
./test-subdirectory-chaining-passthru.sh
./test-static-pod.sh
./test-dra-integration.sh
```

The DRA test validates a preinstalled DRA driver. It does not clone, build, or load an example driver.

### Remove e2e resources

```bash
./teardown.sh
```
