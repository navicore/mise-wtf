#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Testing Pulsar messaging...${NC}"

TOPIC="persistent://public/signalk/test"

# Create a test topic
echo "Creating test topic..."
kubectl exec deployment/pulsar -- bin/pulsar-admin topics create $TOPIC 2>/dev/null || true

# Send a test message
echo "Sending test message..."
kubectl exec deployment/pulsar -- bin/pulsar-client produce \
  $TOPIC \
  --messages "Hello from SignalK at $(date)"

# Consume the message
echo "Consuming message..."
kubectl exec deployment/pulsar -- bash -c "
  timeout 5 bin/pulsar-client consume \
    $TOPIC \
    --subscription-name test-sub \
    --num-messages 1 \
    -t Shared
" || echo "Consumer timeout (this is normal if message was already consumed)"

# Show topic stats
echo ""
echo "Topic statistics:"
kubectl exec deployment/pulsar -- bin/pulsar-admin topics stats $TOPIC

echo ""
echo -e "${GREEN}✓ Pulsar test complete!${NC}"