#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up Nginx Ingress Controller...${NC}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not available. Run 'source .env' first.${NC}"
    exit 1
fi

# Check if cluster is running
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: No kubernetes cluster found. Run './scripts/cluster-create.sh' first.${NC}"
    exit 1
fi

# Install nginx ingress controller
echo "Installing nginx ingress controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress controller to be ready
echo "Waiting for ingress controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Verify ingress controller is running
echo ""
echo "Ingress controller status:"
kubectl -n ingress-nginx get pods
kubectl -n ingress-nginx get svc

# Create a test deployment and ingress
echo ""
echo -e "${YELLOW}Creating test deployment...${NC}"

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      containers:
      - name: hello
        image: nginxdemos/hello
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: hello-world
  namespace: default
spec:
  selector:
    app: hello-world
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-world
  namespace: default
spec:
  ingressClassName: nginx
  rules:
  - host: hello.k8s.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hello-world
            port:
              number: 80
EOF

# Wait for deployment to be ready
kubectl wait --for=condition=available deployment/hello-world --timeout=60s

echo ""
echo -e "${GREEN}✓ Ingress controller installed successfully!${NC}"
echo ""
echo "Test with:"
echo "  curl -H 'Host: hello.k8s.local' http://localhost"
echo ""
echo "Or after setting up DNS:"
echo "  curl http://hello.k8s.local"
echo ""
echo "Current ingresses:"
kubectl get ingress