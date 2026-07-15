# Reproducible Talos Machine Configuration

This directory keeps the declarative inputs required to regenerate Talos machine
configuration. Generated machine configs are intentionally excluded from Git.

`cluster-config.sh` pins the generation contract recovered from the existing
cluster: Talos `v1.12`, Kubernetes `1.35.0`, the cluster endpoint, and installer
settings. Do not change these values while reproducing the current cluster.

## Secrets

`secrets.yaml` is the existing cluster's Talos secrets bundle. It is ignored by
Git and must be backed up in a secure secret store. It is required to create
machine configurations that join this cluster.

## Add a worker node

This workflow uses the stock Talos v1.13.6 Metal ISO and the documented Proxmox
UEFI/q35, VirtIO-SCSI layout. It requires `qm` on the Proxmox host and
`talosctl` on the machine running this repository.

Download the ISO to Proxmox's `local` storage:

```sh
curl -fL \
  https://factory.talos.dev/image/376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba/v1.13.6/metal-amd64.iso \
  -o /var/lib/vz/template/iso/talos-v1.13.6-metal-amd64.iso
```

Create the VM from the Proxmox host. The arguments are VM ID and node name;
the optional arguments are ISO storage reference, disk storage, and bridge.

```sh
./create-proxmox-worker.sh 1013 talos-worker-03
```

Create a node patch from the template, then set its hostname and address:

```sh
cp patches/nodes/example-worker.yaml patches/nodes/talos-worker-03.yaml
# Set the new node's hostname and address in patches/nodes/talos-worker-03.yaml.
./generate-config.sh worker talos-worker-03
```

When the VM enters maintenance mode, apply the generated configuration using
the IP shown in its console:

```sh
talosctl apply-config --insecure --nodes <maintenance-ip> \
  --file generated/talos-worker-03.yaml
```

Then, from the Proxmox host, make the system disk the first boot device and
reboot:

```sh
qm set 1013 --boot 'order=scsi0;ide2;net0'
qm reboot 1013
```

The node will use the static address in its patch after it boots from `scsi0`.

The Terraform-created nodes use different NIC names from the documented Proxmox
worker VM: `talos-cp-01` uses `eth0`, while `talos-worker-01` uses `ens18`.
Keep the node-specific patches instead of moving those settings into a shared
patch.

## Reproduce existing control-plane configuration

```sh
./generate-config.sh controlplane talos-cp-01
```
