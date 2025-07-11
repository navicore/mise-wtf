#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

API_URL="http://api.k8s.local"

echo -e "${GREEN}Testing REST API...${NC}"
echo ""

# Health check
echo "1. Health check:"
curl -s $API_URL/health | jq '.' || echo "Failed"
echo ""

# Ready check
echo "2. Ready check:"
curl -s $API_URL/ready | jq '.' || echo "Failed"
echo ""

# Get observations
echo "3. Get observations:"
curl -s $API_URL/api/observations?limit=5 | jq '.' || echo "Failed"
echo ""

# Get latest observations
echo "4. Get latest observations:"
curl -s $API_URL/api/observations/latest | jq '.' || echo "Failed"
echo ""

# Get vessels
echo "5. Get vessels:"
curl -s $API_URL/api/vessels | jq '.' || echo "Failed"
echo ""

# Get metrics
echo "6. Get metrics:"
curl -s $API_URL/api/metrics | jq '.' || echo "Failed"
echo ""

# Create a new observation
echo "7. Creating new observation:"
NEW_OBS=$(curl -s -X POST $API_URL/api/observations \
  -H "Content-Type: application/json" \
  -d '{
    "vessel_id": "vessel-003",
    "metric_name": "engine.temperature",
    "metric_value": 85.5,
    "unit": "celsius",
    "metadata": {"engine": "main", "sensor": "temp-engine-01"}
  }')
echo $NEW_OBS | jq '.' || echo "Failed"
echo ""

# Get aggregations
echo "8. Get aggregations:"
curl -s $API_URL/api/aggregations | jq '.' || echo "Failed"
echo ""

echo -e "${GREEN}API test complete!${NC}"