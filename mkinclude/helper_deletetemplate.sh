#!/bin/bash
set -eo pipefail

# Optional overrides; fall back to Packer/govc env without tripping nounset.
DATACENTER="${DATACENTER:-${PKR_VAR_vsphere_datacenter:-}}"
CLUSTER="${CLUSTER:-${PKR_VAR_vsphere_cluster:-}}"
GOVC_BIN="${GOVC:-govc}"

VM_NAME="${1:-}"
VM_FOLDER="${2:-}"
VM_POOL="${3:-}"

if [ -z "${VM_NAME}" ] || [ "${VM_NAME}" = "null" ]; then
    echo "error: VM name is empty or null; refusing to delete" >&2
    exit 1
fi

if [ -z "${DATACENTER}" ]; then
    echo "error: DATACENTER / PKR_VAR_vsphere_datacenter is not set" >&2
    exit 1
fi

VMBASEPATH="/${DATACENTER}/vm/${VM_FOLDER}"
VMPATH="${VMBASEPATH%%/}/${VM_NAME}"
POOLPATH="/${DATACENTER}/host/${CLUSTER}/Resources/${VM_POOL}"

if ! "${GOVC_BIN}" vm.info "${VMPATH%%/}" >/dev/null 2>&1; then
    echo "VM ${VMPATH%%/} not found"
    exit 0
fi

# Templates may omit Host; treat missing host as not deletable via markasvm.
esxhost=$("${GOVC_BIN}" vm.info "${VMPATH%%/}" | awk '/Host:/ {print $2; exit}')
if [ -z "${esxhost}" ]; then
    echo "VM ${VMPATH%%/} has no host (already gone or not a VM); skipping delete"
    exit 0
fi

ADDOPT=""
# if VM_POOL is set inject the pool into the command
if [ -n "${VM_POOL}" ] && [ "${VM_POOL}" != "null" ]; then
    ADDOPT="-pool=${POOLPATH}"
fi

# shellcheck disable=SC2086
"${GOVC_BIN}" vm.markasvm -host="$esxhost" -dc="${DATACENTER}" $ADDOPT "${VMPATH%%/}"
"${GOVC_BIN}" vm.destroy "${VMPATH%%/}"
