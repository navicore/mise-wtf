# Quick Wins Checklist

## Today: Validate Podman + Kind

```bash
# After running ./setup.sh and source .env

# 1. Start podman machine
podman machine init --cpus 4 --memory 8192
podman machine start

# 2. Create kind cluster using podman
export KIND_EXPERIMENTAL_PROVIDER=podman
kind create cluster --name k8s-lab

# 3. Test cluster
kubectl cluster-info
kubectl get nodes
```

## Tomorrow: Basic Ingress

```bash
# 1. Install nginx ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# 2. Wait for it to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# 3. Test with simple app
kubectl create deployment hello --image=nginxdemos/hello
kubectl expose deployment hello --port=80
kubectl create ingress hello --rule="hello.k8s.local/*=hello:80"
```

## This Week: DNS Setup

```bash
# 1. Install dnsmasq
brew install dnsmasq

# 2. Configure for *.k8s.local
echo "address=/k8s.local/127.0.0.1" > /usr/local/etc/dnsmasq.conf

# 3. Start dnsmasq
sudo brew services start dnsmasq

# 4. Add to macOS DNS
sudo mkdir -p /etc/resolver
echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/k8s.local

# 5. Test
ping app.k8s.local  # Should resolve to 127.0.0.1
curl hello.k8s.local  # Should hit your ingress
```

## Common Issues & Solutions

### Podman Machine Won't Start
```bash
# Reset podman completely
podman machine stop
podman machine rm
podman system reset
# Then recreate
```

### Kind Can't Find Podman
```bash
# Ensure podman socket is available
podman machine ssh
sudo systemctl enable --now podman.socket
exit
```

### DNS Not Resolving
```bash
# Check dnsmasq is running
sudo brew services list
# Check resolver file exists
cat /etc/resolver/k8s.local
# Flush DNS cache
sudo dscacheutil -flushcache
```

### Ingress Not Working
```bash
# Check ingress controller is running
kubectl -n ingress-nginx get pods
# Check ingress resource
kubectl get ingress
kubectl describe ingress hello
# Port forward directly to test
kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 8080:80
```