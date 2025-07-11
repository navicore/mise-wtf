#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up local Docker registry...${NC}"

REGISTRY_NAME="kind-registry"
REGISTRY_PORT="5001"

# Check if registry container is already running
if podman ps --format "{{.Names}}" | grep -q "^${REGISTRY_NAME}$"; then
    echo "Registry container already running"
else
    echo "Creating registry container..."
    
    # Run registry container with podman
    podman run -d \
        --name ${REGISTRY_NAME} \
        --restart always \
        -p ${REGISTRY_PORT}:5000 \
        registry:2
    
    # Wait for registry to be ready
    echo "Waiting for registry to start..."
    sleep 5
fi

# Get the registry container IP in the podman network
REGISTRY_IP=$(podman inspect ${REGISTRY_NAME} -f '{{.NetworkSettings.IPAddress}}')

# Connect the registry to the kind network if not already connected
echo "Ensuring registry is connected to kind network..."
if ! podman inspect ${REGISTRY_NAME} -f '{{.NetworkSettings.Networks}}' | grep -q "kind"; then
    podman network connect kind ${REGISTRY_NAME}
fi

# Get the registry IP in the kind network
REGISTRY_KIND_IP=$(podman inspect ${REGISTRY_NAME} -f '{{.NetworkSettings.Networks.kind.IPAddress}}')

echo "Registry IPs:"
echo "  - Host access: localhost:${REGISTRY_PORT}"
echo "  - Kind network: ${REGISTRY_KIND_IP}:5000"

# Update containerd config on kind nodes to accept insecure registry
echo "Configuring kind nodes to trust the registry..."
for node in $(kind get nodes --name k8s-lab); do
    podman exec "${node}" bash -c "
        cat > /etc/containerd/config.toml <<EOF
version = 2

[plugins]
  [plugins.\"io.containerd.grpc.v1.cri\"]
    [plugins.\"io.containerd.grpc.v1.cri\".registry]
      [plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors]
        [plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"${REGISTRY_KIND_IP}:5000\"]
          endpoint = [\"http://${REGISTRY_KIND_IP}:5000\"]
        [plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"localhost:${REGISTRY_PORT}\"]
          endpoint = [\"http://${REGISTRY_KIND_IP}:5000\"]
      [plugins.\"io.containerd.grpc.v1.cri\".registry.configs]
        [plugins.\"io.containerd.grpc.v1.cri\".registry.configs.\"${REGISTRY_KIND_IP}:5000\".tls]
          insecure_skip_verify = true
        [plugins.\"io.containerd.grpc.v1.cri\".registry.configs.\"localhost:${REGISTRY_PORT}\".tls]
          insecure_skip_verify = true
EOF
        systemctl restart containerd
    "
done

# Create a ConfigMap with the registry info
echo "Creating registry ConfigMap..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "${REGISTRY_KIND_IP}:5000"
    hostFromClusterNetwork: "${REGISTRY_KIND_IP}:5000"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

echo ""
echo -e "${GREEN}✓ Registry setup complete!${NC}"
echo ""
echo "Registry endpoints:"
echo "  - For podman push: localhost:${REGISTRY_PORT}"
echo "  - For K8s pods: ${REGISTRY_KIND_IP}:5000"
echo ""
echo "To use:"
echo "  1. Tag: podman tag myapp:latest localhost:${REGISTRY_PORT}/myapp:latest"
echo "  2. Push: podman push localhost:${REGISTRY_PORT}/myapp:latest --tls-verify=false"
echo "  3. In K8s: image: ${REGISTRY_KIND_IP}:5000/myapp:latest"

# Save registry info for other scripts
cat > .registry <<EOF
export REGISTRY_HOST=localhost
export REGISTRY_PORT=${REGISTRY_PORT}
export REGISTRY=localhost:${REGISTRY_PORT}
export REGISTRY_K8S=${REGISTRY_KIND_IP}:5000
EOF

echo ""
echo "Registry config saved to .registry"