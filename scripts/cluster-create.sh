#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Creating Kind cluster with Podman...${NC}"

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v podman &> /dev/null; then
    echo -e "${RED}Error: podman is not installed. Run ./setup.sh first.${NC}"
    exit 1
fi

if ! command -v kind &> /dev/null; then
    echo -e "${RED}Error: kind is not installed. Run 'source .env' first.${NC}"
    exit 1
fi

# Check if podman machine exists and is running
if ! podman machine list | grep -q "Currently running"; then
    echo -e "${YELLOW}Podman machine is not running. Starting it...${NC}"
    
    # Check if machine exists
    if ! podman machine list | grep -q "podman-machine-default"; then
        echo "Creating podman machine..."
        podman machine init --cpus 4 --memory 8192 --disk-size 50
    fi
    
    echo "Starting podman machine..."
    podman machine start
    
    # Wait for machine to be ready
    sleep 5
fi

# Verify podman is working
echo "Verifying podman..."
if ! podman info &> /dev/null; then
    echo -e "${RED}Error: podman is not responding. Try 'podman machine rm' and recreate.${NC}"
    exit 1
fi

# Set podman as the provider for kind
export KIND_EXPERIMENTAL_PROVIDER=podman

# Check if cluster already exists
if kind get clusters 2>/dev/null | grep -q "k8s-lab"; then
    echo -e "${YELLOW}Cluster 'k8s-lab' already exists.${NC}"
    read -p "Delete and recreate? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deleting existing cluster..."
        kind delete cluster --name k8s-lab
    else
        echo "Using existing cluster."
        kubectl cluster-info
        exit 0
    fi
fi

# Create kind config for ingress support
echo "Creating kind cluster config..."
cat > /tmp/kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: k8s-lab
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

# Create the cluster
echo "Creating kind cluster 'k8s-lab'..."
if ! kind create cluster --config /tmp/kind-config.yaml; then
    echo -e "${RED}Failed to create cluster. Check podman logs for details.${NC}"
    echo "Try: podman logs kind-control-plane"
    exit 1
fi

# Set kubeconfig context
kubectl cluster-info --context kind-k8s-lab

# Wait for cluster to be ready
echo "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready node --all --timeout=60s

echo -e "${GREEN}✓ Kind cluster created successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Run './scripts/ingress-setup.sh' to install ingress controller"
echo "2. Run './scripts/dns-setup.sh' to configure DNS"
echo ""
echo "Cluster info:"
kubectl get nodes