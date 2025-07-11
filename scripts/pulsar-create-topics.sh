#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Creating Pulsar topics for SignalK observations...${NC}"

# Wait for Pulsar to be ready
echo "Checking Pulsar availability..."
if ! kubectl exec deployment/pulsar -- bin/pulsar-admin brokers healthcheck; then
    echo -e "${YELLOW}Pulsar not ready yet. Please wait and try again.${NC}"
    exit 1
fi

# Create namespace if it doesn't exist
echo "Creating namespace 'signalk'..."
kubectl exec deployment/pulsar -- bin/pulsar-admin namespaces create public/signalk 2>/dev/null || echo "Namespace already exists"

# Create topics
echo "Creating topics..."

# Main topic for all observations
kubectl exec deployment/pulsar -- bin/pulsar-admin topics create persistent://public/signalk/observations || echo "Topic 'observations' already exists"

# Topic for aggregated data
kubectl exec deployment/pulsar -- bin/pulsar-admin topics create persistent://public/signalk/aggregations || echo "Topic 'aggregations' already exists"

# Dead letter topic for failed messages
kubectl exec deployment/pulsar -- bin/pulsar-admin topics create persistent://public/signalk/observations-dlq || echo "Topic 'observations-dlq' already exists"

# Set retention policies (keep data for 7 days)
echo "Setting retention policies..."
kubectl exec deployment/pulsar -- bin/pulsar-admin namespaces set-retention public/signalk \
  --size 1G \
  --time 7d

# List created topics
echo ""
echo "Created topics:"
kubectl exec deployment/pulsar -- bin/pulsar-admin topics list public/signalk

echo ""
echo -e "${GREEN}✓ Topics created successfully!${NC}"
echo ""
echo "Topics available:"
echo "  - persistent://public/signalk/observations - Raw SignalK observations"
echo "  - persistent://public/signalk/aggregations - Aggregated data"
echo "  - persistent://public/signalk/observations-dlq - Dead letter queue"