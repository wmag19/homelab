# Infra Setup

# Talos:

Create an image selecting the following options:


- System Extensions: `isci-tools` & `qemu-guest-agent`

# Proxmox:

API Token (Recommended for Production):

```tf
provider "proxmox" {
  endpoint  = "https://10.0.0.2:8006/"
  api_token = "terraform@pve!provider=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

If you need SSH access, the connection is configured via the optional `ssh` block in the provider block:
```
provider "proxmox" {
  endpoint = "https://10.0.0.2:8006/"
  username = "username@realm"
  password = "a-strong-password"
  insecure = true

  ssh {
    agent = true
  }
}
```


Create `.envrc` file:

```
export PROXMOX_VE_USERNAME="root@pam"
export PROXMOX_VE_PASSWORD=""
export PROXMOX_VE_SSH_USERNAME="root@pam"
export PROXMOX_VE_SSH_PASSWORD=""
```

Image ID: dc7b152cb3ea99b821fcb7340ce7168313ce393d663740b791c36f6e95fc8586
https://factory.talos.dev/?arch=amd64&board=undefined&bootloader=auto&cmdline-set=true&extensions=-&extensions=siderolabs%2Fiscsi-tools&extensions=siderolabs%2Fqemu-guest-agent&platform=nocloud&secureboot=true&target=cloud&version=1.12.6


*Upgrades:* https://github.com/oneuptime/blog/tree/master/posts/2026-03-03-upgrade-talos-linux-clusters-with-terraform


## Setting up:

* terraform init -upgrade
* terraform plan --var-file=lab.tfvars
* terraform apply --var-file=lab.tfvars
* terraform output kubeconfig
* terraform output talosconfig > talosconfig