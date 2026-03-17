# Omni Cluster Setup

0. Setup Infrastructure Provider:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/docker.sh)" 
```

Then copy file:
```config.yaml
proxmox:
  username: root
  password: password
  url: "https://pve1.home:8006/api2/json"
  insecureSkipVerify: true
  realm: "pam"
```

```docker-compose.yaml
services:
  omni-infra-provider-proxmox:
    image: ghcr.io/siderolabs/omni-infra-provider-proxmox
    volumes:
      - ./config.yaml:/config.yaml
    command: >
      --config-file /config.yaml
      --omni-api-endpoint https://<account-name>.omni.siderolabs.io/
      --omni-service-account-key <infrastructure-provider-key>
    restart: unless-stopped
```

1. Setup cluster:
```bash
omnictl cluster template validate -f cluster.yaml

omnictl cluster template sync -f cluster.yaml --verbose

omnictl cluster template status -f cluster.yaml
```