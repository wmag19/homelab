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

# Create temp files in a safe directory
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
command -v helm >/dev/null 2>&1 || { echo "helm not found in PATH" >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl not found in PATH" >&2; exit 1; }
if ! command -v omnictl >/dev/null 2>&1; then
  echo "warning: omnictl not found in PATH (used to fetch Talos kubeconfig)" >&2
fi

echo "3) Download Talos kubeconfig for cluster '$CLUSTER_NAME' (using omnictl)"
omnictl kubeconfig --merge --cluster "$CLUSTER_NAME"


echo "5) Confirm kubectl can access the cluster"
# Use current-context after merge; fail with helpful message
CURRENT_CTX="$(kubectl config current-context || true)"
if [[ -z "$CURRENT_CTX" ]]; then
  echo "No current-context set in kubeconfig." >&2
  exit 1
fi

if ! kubectl --context "$CURRENT_CTX" get nodes >/dev/null 2>&1; then
  echo "kubectl failed to list nodes for context '$CURRENT_CTX'; check kubeconfig/context." >&2
  exit 1
fi
echo "kubectl can access the cluster using context: $CURRENT_CTX"

echo "6) Wait for 30s to give Argo CD time to initialize"
sleep 30

echo "7) Apply bootstrap manifest: $BOOTSTRAP_MANIFEST"
kubectl apply -f "$BOOTSTRAP_MANIFEST"

echo "Done."

echo "2) Add/update Helm repo and install/upgrade Argo CD"
helm repo add "$HELM_REPO_NAME" "$HELM_REPO_URL" >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1 || true
helm upgrade --install "$RELEASE_NAME" "$HELM_REPO_NAME/$CHART" \
  --version "$CHART_VERSION" \
  --namespace "$NAMESPACE" --create-namespace \
  -f "$VALUES_FILE"


