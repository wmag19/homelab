#!/bin/bash

set -e

up() {
    echo "Bringing up Talos cluster..."
    
    # Ensure SSH agent is running and key is loaded
    if ! ssh-add -L >/dev/null 2>&1; then
        echo "Starting SSH agent and adding key..."
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/id_ed25519 2>/dev/null || {
            echo "Failed to add SSH key. Make sure ~/.ssh/id_ed25519 exists."
            exit 1
        }
    fi
    
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
    echo "⚠️  WARNING: This will destroy the Talos cluster and all applications!"
    echo "This action cannot be undone."
    echo
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirmation
    
    if [ "$confirmation" != "yes" ]; then
        echo "Cluster shutdown cancelled."
        return 1
    fi
    
    echo "Bringing down Talos cluster (preserving ISO)..."
    
    # Clean up ArgoCD applications first to prevent finalizer issues
    echo "Cleaning up ArgoCD applications..."
    if kubectl get apps -n argocd >/dev/null 2>&1; then
        # Remove finalizers from all applications
        for app in $(kubectl get apps -n argocd -o name 2>/dev/null); do
            echo "Removing finalizers from $app"
            kubectl patch "$app" -n argocd -p '{"metadata": {"finalizers": null}}' --type merge 2>/dev/null || true
        done
        
        # Delete all applications
        kubectl delete apps --all -n argocd --timeout=30s 2>/dev/null || true
        
        # Clean up applicationsets
        for appset in $(kubectl get applicationsets -n argocd -o name 2>/dev/null); do
            echo "Removing finalizers from $appset"
            kubectl patch "$appset" -n argocd -p '{"metadata": {"finalizers": null}}' --type merge 2>/dev/null || true
        done
        kubectl delete applicationsets --all -n argocd --timeout=30s 2>/dev/null || true
    else
        echo "No ArgoCD applications found or cluster not accessible, proceeding with terraform destroy..."
    fi
    
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