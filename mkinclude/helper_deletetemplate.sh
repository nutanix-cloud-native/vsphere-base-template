#!/bin/bash
set -euo pipefail

DATACENTER=${DATACENTER:-$PKR_VAR_vsphere_datacenter}
CLUSTER=${CLUSTER:-$PKR_VAR_vsphere_cluster}

VM_NAME="${1:-}"
VM_FOLDER="${2:-}"
VM_POOL="${3:-}"

if [ -z "${VM_NAME}" ] || [ "${VM_NAME}" = "null" ]; then
    echo "error: VM name is empty or null; refusing to delete" >&2
    exit 1
fi

VMBASEPATH="/${DATACENTER}/vm/${VM_FOLDER}"
VMPATH="${VMBASEPATH%%/}/${VM_NAME}"
POOLPATH="/${DATACENTER}/host/${CLUSTER}/Resources/${VM_POOL}"

if ! govc vm.info "${VMPATH%%/}" >/dev/null 2>&1; then
    echo "VM ${VMPATH%%/} not found"
    exit 0
fi

esxhost=$(govc vm.info "${VMPATH%%/}" | grep 'Host:' | awk '{print $2}')
if [ -z "${esxhost}" ]; then
    echo "VM ${VMPATH%%/} not found"
    exit 0
fi

ADDOPT=""
# if VM_POOL is set inject the pool into the command
if [ -n "${VM_POOL}" ] && [ "${VM_POOL}" != "null" ]; then
    ADDOPT="-pool=${POOLPATH}"
fi

# shellcheck disable=SC2086
govc vm.markasvm -host="$esxhost" -dc="${DATACENTER}" $ADDOPT "${VMPATH%%/}"
govc vm.destroy "${VMPATH%%/}"
