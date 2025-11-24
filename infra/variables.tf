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
  default     = "https://factory.talos.dev/image/376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba/v1.11.5/nocloud-amd64.raw.xz"
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