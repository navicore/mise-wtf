#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up REST API...${NC}"

# Check if cluster is running
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: No kubernetes cluster found. Run 'make cluster' first.${NC}"
    exit 1
fi

# Check if PostgreSQL is running
if ! kubectl get pod postgres-0 &> /dev/null; then
    echo -e "${RED}Error: PostgreSQL not found. Run 'make postgres' first.${NC}"
    exit 1
fi

# Source registry config
if [ -f .registry ]; then
    source .registry
else
    echo -e "${YELLOW}Registry not configured. Running registry setup...${NC}"
    ./scripts/registry-setup.sh
    source .registry
fi

# Build the Docker image using podman
echo "Building REST API Docker image..."
cd services/rest-api
podman build -t rest-api:latest .

# Tag for registry
echo "Tagging image for registry..."
podman tag rest-api:latest ${REGISTRY}/rest-api:latest

# Push to registry
echo "Pushing to local registry..."
podman push ${REGISTRY}/rest-api:latest --tls-verify=false

# Update the deployment to use registry image
cd ../..
cat > k8s/rest-api/deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rest-api
  namespace: default
  labels:
    app: rest-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: rest-api
  template:
    metadata:
      labels:
        app: rest-api
    spec:
      containers:
      - name: rest-api
        image: ${REGISTRY_K8S}/rest-api:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          valueFrom:
            configMapKeyRef:
              name: postgres-config
              key: DATABASE_URL
        - name: PORT
          value: "3000"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
EOF

# Deploy to Kubernetes
echo "Deploying REST API to Kubernetes..."
kubectl apply -f k8s/rest-api/deployment.yaml
kubectl apply -f k8s/rest-api/service.yaml
kubectl apply -f k8s/rest-api/ingress.yaml

# Wait for deployment to be ready
echo "Waiting for REST API to be ready..."
kubectl rollout status deployment/rest-api --timeout=120s

# Show deployment status
echo ""
echo "REST API deployment status:"
kubectl get deployment rest-api
kubectl get pods -l app=rest-api
kubectl get ingress rest-api

echo ""
echo -e "${GREEN}✓ REST API setup complete!${NC}"
echo ""
echo "API endpoints available at http://api.k8s.local:"
echo "  GET  /health              - Health check"
echo "  GET  /ready               - Readiness check"
echo "  GET  /api/observations    - List observations"
echo "  POST /api/observations    - Create observation"
echo "  GET  /api/observations/latest - Latest observations"
echo "  GET  /api/aggregations    - List aggregations"
echo "  POST /api/aggregations    - Create/update aggregation"
echo "  GET  /api/vessels         - List vessels"
echo "  GET  /api/metrics         - List metrics"
echo ""
echo "Test with:"
echo "  curl http://api.k8s.local/health"
echo "  curl http://api.k8s.local/api/observations"