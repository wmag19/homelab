# homelab
My Kubernetes homelab

## Prereqs:

* SSH Key added to Proxmox host
* Environment variables set up - PROXMOX_VE_API_TOKEN

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