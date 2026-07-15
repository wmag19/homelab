#!/bin/sh

set -eu

usage() {
    echo "Usage: $0 <controlplane|worker> <node-name>" >&2
    exit 1
}

[ "$#" -eq 2 ] || usage

machine_type="$1"
node_name="$2"
config_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
node_patch="$config_dir/patches/nodes/$node_name.yaml"
output_dir="$config_dir/generated"

case "$machine_type" in
    controlplane|worker) ;;
    *) usage ;;
esac

[ -f "$config_dir/secrets.yaml" ] || {
    echo "Missing secrets bundle: $config_dir/secrets.yaml" >&2
    exit 1
}
[ -f "$node_patch" ] || {
    echo "Missing node patch: $node_patch" >&2
    exit 1
}

. "$config_dir/cluster-config.sh"

mkdir -p "$output_dir"

set -- \
    talosctl gen config "$CLUSTER_NAME" "$CLUSTER_ENDPOINT" \
    --with-secrets "$config_dir/secrets.yaml" \
    --kubernetes-version "$KUBERNETES_VERSION" \
    --talos-version "$TALOS_VERSION" \
    --install-disk "$INSTALL_DISK" \
    --install-image "$INSTALL_IMAGE" \
    --with-docs=false \
    --with-examples=false \
    --config-patch "@$node_patch" \
    --output-types "$machine_type" \
    --output "$output_dir/$node_name.yaml" \
    --force

role_patch="$config_dir/patches/$machine_type.yaml"
if [ -f "$role_patch" ]; then
    set -- "$@" --config-patch "@$role_patch"
fi

"$@"
