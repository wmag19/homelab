# homelab
My Kubernetes homelab

## Prereqs:

* SSH Key added to Proxmox host:
```bash
ssh-copy-id user@remote_host
ssh-add -L
```
* Environment variables set up - PROXMOX_VE_API_TOKEN

```bash
1. pveum user add terraform@pve
2. pveum role add Terraform -privs "Realm.AllocateUser, VM.PowerMgmt, VM.GuestAgent.Unrestricted, Sys.Console, Sys.Audit, Sys.AccessNetwork, VM.Config.Cloudinit, VM.Replicate, Pool.Allocate, SDN.Audit, Realm.Allocate, SDN.Use, Mapping.Modify, VM.Config.Memory, VM.GuestAgent.FileSystemMgmt, VM.Allocate, SDN.Allocate, VM.Console, VM.Clone, VM.Backup, Datastore.AllocateTemplate, VM.Snapshot, VM.Config.Network, Sys.Incoming, Sys.Modify, VM.Snapshot.Rollback, VM.Config.Disk, Datastore.Allocate, VM.Config.CPU, VM.Config.CDROM, Group.Allocate, Datastore.Audit, VM.Migrate, VM.GuestAgent.FileWrite, Mapping.Use, Datastore.AllocateSpace, Sys.Syslog, VM.Config.Options, Pool.Audit, User.Modify, VM.Config.HWType, VM.Audit, Sys.PowerMgmt, VM.GuestAgent.Audit, Mapping.Audit, VM.GuestAgent.FileRead, Permissions.Modify"
3. pveum aclmod / -user terraform@pve -role Terraform
4. pveum user token add terraform@pve provider --privsep=0
```

## Setup:

Run script 
```
/infra/cluster.sh up
```

This script runs the following steps:

## TODO:
```
╷
│ Warning: Deprecated
│ 
│   with data.talos_cluster_kubeconfig.kubeconfig,
│   on cluster.tf line 70, in data "talos_cluster_kubeconfig" "kubeconfig":
│   70: data "talos_cluster_kubeconfig" "kubeconfig" {
│ 
│ Use `talos_cluster_kubeconfig` resource instead. This data source will be removed in the next
│ minor version of the provider.
```