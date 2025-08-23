provider "proxmox" {
  endpoint = var.pve_endpoint
  insecure = true # Only needed if your Proxmox server is using a self-signed certificate

  ssh {
    agent    = true
    username = "root"
  }
}
