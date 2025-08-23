#!/bin/bash

set -e

up() {
    echo "Bringing up Talos cluster..."
    
    # Apply terraform configuration
    terraform apply -var-file=lab.tfvars -auto-approve
    
    echo "Cluster deployed successfully!"
    
    # Create directories if they don't exist
    mkdir -p "$HOME/.kube"
    mkdir -p "$HOME/.talos"
    
    echo "Extracting kubeconfig..."
    terraform output -raw kubeconfig > "$HOME/.kube/config"
    chmod 600 "$HOME/.kube/config"
    
    echo "Extracting talosconfig..."
    terraform output -raw talosconfig > "$HOME/.talos/config"
    chmod 600 "$HOME/.talos/config"
    
    echo "Configuration files written to:"
    echo "  - Kubeconfig: $HOME/.kube/config"
    echo "  - Talosconfig: $HOME/.talos/config"
    
    echo "Cluster is ready!"
}

down() {
    echo "Bringing down Talos cluster (preserving ISO)..."
    
    # Destroy everything except the ISO download
    terraform destroy -var-file=lab.tfvars \
        -target=proxmox_virtual_environment_vm.talos_cp_01 \
        -target=proxmox_virtual_environment_vm.talos_worker_01 \
        -target=talos_machine_secrets.machine_secrets \
        -target=talos_machine_configuration_apply.cp_config_apply \
        -target=talos_machine_configuration_apply.worker_config_apply \
        -target=talos_machine_bootstrap.bootstrap \
        -target=helm_release.argocd \
        -target=kubernetes_namespace.argocd \
        -target=null_resource.apply_applicationset \
        -auto-approve
    
    echo "Cluster destroyed (ISO preserved for faster redeployment)"
}

down_all() {
    echo "Destroying all Terraform resources..."
    
    # Destroy everything
    terraform destroy -var-file=lab.tfvars -auto-approve
    
    echo "All resources destroyed"
}

case "$1" in
    up)
        up
        ;;
    down)
        down
        ;;
    down-all)
        down_all
        ;;
    *)
        echo "Usage: $0 {up|down|down-all}"
        echo "  up       - Deploy the Talos cluster"
        echo "  down     - Destroy the Talos cluster (preserves ISO)"
        echo "  down-all - Destroy all Terraform resources including ISO"
        exit 1
        ;;
esac