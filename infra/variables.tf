variable "cluster_name" {
  type    = string
  default = ""
}

variable "default_gateway" {
  type    = string
  default = ""
}

variable "talos_cp_01_ip_addr" {
  type    = string
  default = ""
}

variable "talos_worker_01_ip_addr" {
  type    = string
  default = ""
}

variable "image_url" {
  type        = string
  default     = "https://factory.talos.dev/image/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515/v1.10.6/nocloud-amd64.raw.xz"
  description = "URL for Talos Linux Disk Image"
}

variable "pve_node_name" {
  description = "Name of Proxmox Node"
  default     = ""
}

variable "pve_endpoint" {
  description = "Full URL for Proxmox Node"
  default     = ""
}