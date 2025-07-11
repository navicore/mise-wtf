#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Validating K8s Lab Setup...${NC}"
echo "=========================="

# Function to check command
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "✓ $1 is installed"
        return 0
    else
        echo -e "${RED}✗ $1 is not installed${NC}"
        return 1
    fi
}

# Function to check service
check_service() {
    if $1 &> /dev/null; then
        echo -e "✓ $2"
        return 0
    else
        echo -e "${RED}✗ $2${NC}"
        return 1
    fi
}

# Check tools
echo ""
echo "Checking tools..."
check_command mise
check_command podman
check_command kind
check_command kubectl
check_command flux

# Check podman
echo ""
echo "Checking Podman..."
if podman machine list | grep -q "Currently running"; then
    echo -e "✓ Podman machine is running"
    podman version --format "  Version: {{.Client.Version}}"
else
    echo -e "${RED}✗ Podman machine is not running${NC}"
    echo "  Run: podman machine start"
fi

# Check kind cluster
echo ""
echo "Checking Kind cluster..."
if kind get clusters 2>/dev/null | grep -q "k8s-lab"; then
    echo -e "✓ Kind cluster 'k8s-lab' exists"
    if kubectl cluster-info &> /dev/null; then
        echo -e "✓ Cluster is accessible"
        kubectl get nodes --no-headers | while read line; do
            echo "  Node: $line"
        done
    else
        echo -e "${RED}✗ Cannot connect to cluster${NC}"
    fi
else
    echo -e "${RED}✗ Kind cluster 'k8s-lab' not found${NC}"
    echo "  Run: ./scripts/cluster-create.sh"
fi

# Check ingress
echo ""
echo "Checking Ingress..."
if kubectl -n ingress-nginx get deploy ingress-nginx-controller &> /dev/null; then
    echo -e "✓ Nginx ingress controller is installed"
    READY=$(kubectl -n ingress-nginx get deploy ingress-nginx-controller -o jsonpath='{.status.readyReplicas}')
    if [ "$READY" = "1" ]; then
        echo -e "✓ Ingress controller is ready"
    else
        echo -e "${YELLOW}⚠ Ingress controller is not ready${NC}"
    fi
else
    echo -e "${RED}✗ Nginx ingress controller not found${NC}"
    echo "  Run: ./scripts/ingress-setup.sh"
fi

# Check DNS
echo ""
echo "Checking DNS..."
if [ -f /etc/resolver/k8s.local ]; then
    echo -e "✓ DNS resolver configured"
    if dig +short test.k8s.local | grep -q "127.0.0.1"; then
        echo -e "✓ DNS resolution working (test.k8s.local → 127.0.0.1)"
    else
        echo -e "${YELLOW}⚠ DNS resolution not working${NC}"
    fi
else
    echo -e "${RED}✗ DNS resolver not configured${NC}"
    echo "  Run: ./scripts/dns-setup.sh"
fi

# Test end-to-end
echo ""
echo "Testing end-to-end..."
if kubectl get ingress hello-world &> /dev/null 2>&1; then
    echo -e "✓ Test ingress exists"
    if curl -s --fail --max-time 5 http://hello.k8s.local > /dev/null; then
        echo -e "${GREEN}✓ Full stack working! http://hello.k8s.local is accessible${NC}"
    else
        echo -e "${YELLOW}⚠ Cannot reach http://hello.k8s.local${NC}"
        echo "  Check: curl -v http://hello.k8s.local"
    fi
else
    echo -e "${YELLOW}⚠ Test ingress not found${NC}"
fi

echo ""
echo "=========================="
echo "Validation complete!"