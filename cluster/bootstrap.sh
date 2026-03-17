#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./bootstrap-argocd.sh <cluster-name> <path-to-bootstrap-manifest>
# Example:
#   ./bootstrap-argocd.sh my-cluster ./bootstrap-app.yaml

CLUSTER_NAME="${1:-}"
BOOTSTRAP_MANIFEST="${2:-./bootstrap-app.yaml}"

if [[ -z "$CLUSTER_NAME" ]]; then
  echo "Usage: $0 <cluster-name> <path-to-bootstrap-manifest>"
  exit 1
fi

if [[ ! -f "$BOOTSTRAP_MANIFEST" ]]; then
  echo "Bootstrap manifest not found: $BOOTSTRAP_MANIFEST"
  exit 1
fi

# Config
NAMESPACE="argocd"
RELEASE_NAME="argocd"
HELM_REPO_NAME="argo-helm"
HELM_REPO_URL="https://argoproj.github.io/argo-helm"
CHART="argo-cd"
CHART_VERSION="8.3.0"

VALUES_FILE="$(mktemp --suffix=-argocd-values.yaml)"
DOWNLOADED_KUBECONFIG="$(mktemp --suffix=-kubeconfig.yaml)"

cleanup() {
  rm -f "$VALUES_FILE" "$DOWNLOADED_KUBECONFIG"
}
trap cleanup EXIT

cat > "$VALUES_FILE" <<EOF
global:
  domain: "argocd.local"
configs:
  params:
    server.insecure: true
server:
  service:
    type: NodePort
    nodePortHttp: 30080
EOF

echo "1) Ensure helm and kubectl are available"
command -v helm >/dev/null || { echo "helm not found in PATH"; exit 1; }
command -v kubectl >/dev/null || { echo "kubectl not found in PATH"; exit 1; }
command -v omnictl >/dev/null || echo "warning: omnictl not found in PATH (used to fetch talos kubeconfig)"

echo "2) Add/update Helm repo and install/upgrade Argo CD"
helm repo add "$HELM_REPO_NAME" "$HELM_REPO_URL" || true
helm repo update
helm upgrade --install "$RELEASE_NAME" "$HELM_REPO_NAME/$CHART" \
  --version "$CHART_VERSION" \
  --namespace "$NAMESPACE" --create-namespace \
  -f "$VALUES_FILE"

echo "3) Download Talos kubeconfig for cluster '$CLUSTER_NAME' (using omnictl)"
if command -v omnictl >/dev/null; then
  omnictl kubeconfig --cluster "$CLUSTER_NAME" > "$DOWNLOADED_KUBECONFIG"
else
  echo "omnictl not found; please download the Talos kubeconfig to: $DOWNLOADED_KUBECONFIG"
  echo "Then re-run this script or paste the kubeconfig at that path."
  exit 1
fi

echo "4) Merge downloaded kubeconfig with existing kubeconfig"
mkdir -p ~/.kube
touch ~/.kube/config

export KUBECONFIG="$HOME/.kube/config:$DOWNLOADED_KUBECONFIG"
kubectl config view --flatten > "$HOME/.kube/config.tmp"
mv "$HOME/.kube/config.tmp" "$HOME/.kube/config"
unset KUBECONFIG

echo "5) Confirm kubectl can access the cluster"
kubectl get nodes --context "$(kubectl config current-context)" || {
  echo "kubectl failed to list nodes; check kubeconfig/context."
  exit 1
}

echo "6) Wait for 30s to give Argo CD time to initialize"
sleep 30

echo "7) Apply bootstrap manifest: $BOOTSTRAP_MANIFEST"
kubectl apply -f "$BOOTSTRAP_MANIFEST"

echo "Done."
