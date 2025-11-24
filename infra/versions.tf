terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.82.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.9.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "proxmox" {
  endpoint = var.pve_endpoint
  insecure = true # Only needed if your Proxmox server is using a self-signed certificate

  ssh {
    agent    = true
    username = "root"
  }
}

locals {
  talos = {
    version = "v1.10.6"
  }
}