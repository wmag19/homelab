resource "talos_machine_secrets" "machine_secrets" {}

data "talos_client_configuration" "talosconfig" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoints            = [proxmox_virtual_environment_vm.talos_cp_01.ipv4_addresses[7][0]]
}

data "talos_machine_configuration" "machineconfig_cp" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${proxmox_virtual_environment_vm.talos_cp_01.ipv4_addresses[7][0]}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
}

resource "talos_machine_configuration_apply" "cp_config_apply" {
  depends_on                  = [ proxmox_virtual_environment_vm.talos_cp_01 ]
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machineconfig_cp.machine_configuration
  count                       = 1
  node                        = proxmox_virtual_environment_vm.talos_cp_01.ipv4_addresses[7][0]
}

data "talos_machine_configuration" "machineconfig_worker" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${proxmox_virtual_environment_vm.talos_cp_01.ipv4_addresses[7][0]}:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
}

resource "talos_machine_configuration_apply" "worker_config_apply" {
  depends_on                  = [ proxmox_virtual_environment_vm.talos_worker_01 ]
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machineconfig_worker.machine_configuration
  count                       = 1
  node                        = proxmox_virtual_environment_vm.talos_worker_01.ipv4_addresses[7][0]
}

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on           = [ talos_machine_configuration_apply.cp_config_apply ]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = proxmox_virtual_environment_vm.talos_cp_01.ipv4_addresses[7][0]
}

data "talos_cluster_health" "health" {
  depends_on           = [ talos_machine_configuration_apply.cp_config_apply, talos_machine_configuration_apply.worker_config_apply ]
  client_configuration = data.talos_client_configuration.talosconfig.client_configuration
  control_plane_nodes  = [ proxmox_virtual_environment_vm.talos_cp_01.ipv4_addresses[7][0] ]
  worker_nodes         = [ proxmox_virtual_environment_vm.talos_worker_01.ipv4_addresses[7][0] ]
  endpoints            = data.talos_client_configuration.talosconfig.endpoints
}

data "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on           = [ talos_machine_bootstrap.bootstrap, data.talos_cluster_health.health ]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = proxmox_virtual_environment_vm.talos_cp_01.ipv4_addresses[7][0]
}

output "talosconfig" {
  value = data.talos_client_configuration.talosconfig.talos_config
  sensitive = true
}

output "kubeconfig" {
  value = data.talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  sensitive = true
}
