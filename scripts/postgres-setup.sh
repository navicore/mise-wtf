#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up PostgreSQL...${NC}"

# Check if cluster is running
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: No kubernetes cluster found. Run 'make cluster' first.${NC}"
    exit 1
fi

# Apply PostgreSQL manifests
echo "Deploying PostgreSQL..."
kubectl apply -f k8s/postgres/configmap.yaml
kubectl apply -f k8s/postgres/pvc.yaml
kubectl apply -f k8s/postgres/statefulset.yaml
kubectl apply -f k8s/postgres/service.yaml

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s

# Give it a few more seconds to fully initialize
sleep 5

# Check if PostgreSQL is accepting connections
echo "Verifying PostgreSQL connection..."
kubectl exec -it postgres-0 -- pg_isready -U apiuser -d observations

# Initialize schema
echo ""
echo -e "${YELLOW}Initializing database schema...${NC}"
kubectl exec -i postgres-0 -- psql -U apiuser -d observations < k8s/postgres/init-schema.sql

# Show tables
echo ""
echo "Database tables:"
kubectl exec -it postgres-0 -- psql -U apiuser -d observations -c "\dt"

echo ""
echo -e "${GREEN}✓ PostgreSQL setup complete!${NC}"
echo ""
echo "Connection info:"
echo "  Host: postgres (internal)"
echo "  Port: 5432"
echo "  Database: observations"
echo "  User: apiuser"
echo "  Password: localdevpassword"
echo ""
echo "To connect from your local machine:"
echo "  kubectl port-forward svc/postgres 5432:5432"
echo "  psql postgresql://apiuser:localdevpassword@localhost:5432/observations"
echo ""
echo "To connect from within the cluster:"
echo "  kubectl run psql --rm -it --image=postgres:15-alpine -- psql postgresql://apiuser:localdevpassword@postgres:5432/observations"