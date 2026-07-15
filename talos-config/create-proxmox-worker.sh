#!/bin/sh

set -eu

usage() {
    echo "Usage: $0 <vm-id> <node-name> [iso] [storage] [bridge]" >&2
    exit 1
}

[ "$#" -ge 2 ] && [ "$#" -le 5 ] || usage

vm_id="$1"
node_name="$2"
iso="${3:-local:iso/talos-v1.13.6-metal-amd64.iso}"
storage="${4:-local-lvm}"
bridge="${5:-vmbr0}"

command -v qm >/dev/null 2>&1 || {
    echo "This script must run on a Proxmox host." >&2
    exit 1
}

if qm status "$vm_id" >/dev/null 2>&1; then
    echo "VM $vm_id already exists; refusing to overwrite it." >&2
    exit 1
fi

qm create "$vm_id" \
    --name "$node_name" \
    --ostype l26 \
    --bios ovmf \
    --machine q35 \
    --cores 4 \
    --cpu host \
    --memory 8192 \
    --balloon 0 \
    --scsihw virtio-scsi-pci \
    --net0 "virtio,bridge=$bridge,firewall=0" \
    --serial0 socket \
    --onboot 1

qm set "$vm_id" --efidisk0 "$storage:0,efitype=4m,pre-enrolled-keys=0"
qm set "$vm_id" --scsi0 "$storage:20,cache=writethrough,discard=on,ssd=1"
qm set "$vm_id" --ide2 "$iso,media=cdrom"
qm set "$vm_id" --boot "order=ide2;scsi0;net0"
qm start "$vm_id"

echo "VM $vm_id started from $iso. Apply its Talos config in maintenance mode."
