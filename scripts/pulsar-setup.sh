#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up Apache Pulsar...${NC}"

# Check if cluster is running
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: No kubernetes cluster found. Run 'make cluster' first.${NC}"
    exit 1
fi

# Deploy Pulsar
echo "Deploying Pulsar..."
kubectl apply -f k8s/pulsar/configmap.yaml
kubectl apply -f k8s/pulsar/pvc.yaml
kubectl apply -f k8s/pulsar/deployment.yaml
kubectl apply -f k8s/pulsar/service.yaml
kubectl apply -f k8s/pulsar/ingress.yaml

# Wait for Pulsar to be ready
echo "Waiting for Pulsar to be ready (this may take a few minutes)..."
kubectl wait --for=condition=available deployment/pulsar --timeout=300s

# Give it some extra time to fully initialize
echo "Waiting for Pulsar to fully initialize..."
sleep 20

# Check Pulsar health
echo "Checking Pulsar health..."
kubectl exec deployment/pulsar -- curl -sf http://localhost:8080/admin/v2/brokers/health || echo "Health check pending..."

echo ""
echo -e "${GREEN}✓ Pulsar setup complete!${NC}"
echo ""
echo "Pulsar endpoints:"
echo "  - Admin UI: http://pulsar.k8s.local"
echo "  - Broker (internal): pulsar://pulsar:6650"
echo "  - HTTP API (internal): http://pulsar:8080"
echo ""
echo "To test Pulsar:"
echo "  1. Visit http://pulsar.k8s.local for the admin interface"
echo "  2. Create topics: make pulsar-create-topics"
echo "  3. Test producer/consumer: make pulsar-test"
echo ""
echo "Common Pulsar operations:"
echo "  - List topics: kubectl exec deployment/pulsar -- bin/pulsar-admin topics list public/default"
echo "  - Create topic: kubectl exec deployment/pulsar -- bin/pulsar-admin topics create persistent://public/default/test-topic"