resource "proxmox_virtual_environment_vm" "talos_cp_01" {
  name        = "talos-cp-01"
  description = "Managed by Terraform"
  tags        = ["terraform"]
  node_name   = var.pve_node_name
  on_boot     = true

  cpu {
    cores = 2
    type = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.talos_nocloud_image.id
    file_format  = "raw"
    interface    = "virtio0"
    size         = 20
  }

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 5.X.
  }

  initialization {
    datastore_id = "local-lvm"
    ip_config {
      ipv4 {
        #address = "${var.talos_cp_01_ip_addr}/24"
        address = "dhcp"
        #gateway = var.default_gateway
      }
      ipv6 {
        address = "dhcp"
      }
    }
  }
}

resource "proxmox_virtual_environment_vm" "talos_worker_01" {
  depends_on = [ proxmox_virtual_environment_vm.talos_cp_01 ]
  name        = "talos-worker-01"
  description = "Managed by Terraform"
  tags        = ["terraform"]
  node_name   = var.pve_node_name
  on_boot     = true

  cpu {
    cores = 4
    type = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.talos_nocloud_image.id
    file_format  = "raw"
    interface    = "virtio0"
    size         = 20
  }

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 5.X.
  }

  initialization {
    datastore_id = "local-lvm"
    ip_config {
      ipv4 {
        #address = "${var.talos_worker_01_ip_addr}/24"
        address = "dhcp"
        #gateway = var.default_gateway
      }
      ipv6 {
        address = "dhcp"
      }
    }
  }
}

output "worker_01_ip_address" {
  value = [for addr_list in proxmox_virtual_environment_vm.talos_worker_01.ipv4_addresses : addr_list if length(addr_list) > 0 && addr_list[0] != "127.0.0.1"][0][0]
}

output "cp_01_ip_address" {
  value = [for addr_list in proxmox_virtual_environment_vm.talos_cp_01.ipv4_addresses : addr_list if length(addr_list) > 0 && addr_list[0] != "127.0.0.1"][0][0]
}