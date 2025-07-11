#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up DNS for *.k8s.local...${NC}"

# Check if dnsmasq is installed
if ! command -v dnsmasq &> /dev/null; then
    echo -e "${YELLOW}Installing dnsmasq...${NC}"
    brew install dnsmasq
fi

# Configure dnsmasq
echo "Configuring dnsmasq..."
DNSMASQ_CONF="/usr/local/etc/dnsmasq.conf"

# Backup existing config if it exists
if [ -f "$DNSMASQ_CONF" ]; then
    cp "$DNSMASQ_CONF" "${DNSMASQ_CONF}.backup.$(date +%Y%m%d%H%M%S)"
fi

# Add our configuration
if ! grep -q "address=/k8s.local/127.0.0.1" "$DNSMASQ_CONF" 2>/dev/null; then
    echo "address=/k8s.local/127.0.0.1" >> "$DNSMASQ_CONF"
    echo "Added *.k8s.local configuration to dnsmasq"
else
    echo "*.k8s.local already configured in dnsmasq"
fi

# Start/restart dnsmasq
echo "Starting dnsmasq service..."
if brew services list | grep -q "dnsmasq.*started"; then
    sudo brew services restart dnsmasq
else
    sudo brew services start dnsmasq
fi

# Configure macOS resolver
echo "Configuring macOS resolver..."
sudo mkdir -p /etc/resolver

# Create resolver file for k8s.local domain
echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/k8s.local > /dev/null

# Flush DNS cache
echo "Flushing DNS cache..."
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder 2>/dev/null || true

# Test DNS resolution
echo ""
echo "Testing DNS resolution..."
sleep 2

if ping -c 1 test.k8s.local &> /dev/null; then
    echo -e "${GREEN}✓ DNS resolution working!${NC}"
    echo "  test.k8s.local resolves to: $(dig +short test.k8s.local)"
else
    echo -e "${YELLOW}Warning: DNS resolution test failed. This might be normal if it's the first setup.${NC}"
    echo "Try manually: dig test.k8s.local"
fi

# Test with curl if ingress is set up
if kubectl get ingress hello-world &> /dev/null 2>&1; then
    echo ""
    echo "Testing ingress with DNS..."
    if curl -s --fail --max-time 5 http://hello.k8s.local > /dev/null; then
        echo -e "${GREEN}✓ Ingress accessible via DNS!${NC}"
        echo "Try: curl http://hello.k8s.local"
    else
        echo -e "${YELLOW}Ingress not accessible yet. Make sure ingress controller is running.${NC}"
    fi
fi

echo ""
echo -e "${GREEN}DNS setup complete!${NC}"
echo ""
echo "Configuration:"
echo "  - All *.k8s.local domains resolve to 127.0.0.1"
echo "  - dnsmasq config: $DNSMASQ_CONF"
echo "  - macOS resolver: /etc/resolver/k8s.local"
echo ""
echo "Test with:"
echo "  dig app.k8s.local"
echo "  curl http://hello.k8s.local"