#!/usr/bin/env bash
set -euo pipefail

echo "Setting up Mac K8s Lab..."

# Install mise if not already installed
if ! command -v mise &> /dev/null; then
    echo "Installing mise..."
    curl https://mise.run | sh
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "IMPORTANT: mise has been installed but NOT activated in your shell."
    echo ""
    echo "To activate mise globally, add one of these to your shell config:"
    echo ""
    echo "For bash (~/.bashrc or ~/.bash_profile):"
    echo '  eval "$(~/.local/bin/mise activate bash)"'
    echo ""
    echo "For zsh (~/.zshrc):"
    echo '  eval "$(~/.local/bin/mise activate zsh)"'
    echo ""
    echo "For this project only, you can source the .env file:"
    echo '  source .env'
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Press Enter to continue..."
    read
fi

# Check if mise is in PATH
if ! command -v mise &> /dev/null; then
    echo "mise is not in your PATH. Please activate mise and run this script again."
    echo "You can activate it by running: source .env"
    exit 1
fi

# Install tools via mise
echo "Installing development tools via mise..."
mise install

# Install brew-only tools
echo "Installing podman and bash via brew..."
brew install podman bash

# Verify podman has gvproxy
echo ""
echo "Verifying podman installation..."
if podman machine list &> /dev/null; then
    echo "✓ Podman installed successfully with gvproxy support"
else
    echo "✗ Podman installation may have issues"
fi

# Show installed versions
echo -e "\nInstalled versions:"
echo "Node: $(node --version 2>/dev/null || echo 'not installed')"
echo "Java: $(java --version 2>&1 | head -n1)"
echo "Go: $(go version 2>/dev/null || echo 'not installed')"
echo "Python: $(python --version 2>/dev/null || echo 'not installed')"
echo "kubectl: $(kubectl version --client -o yaml | grep gitVersion | head -1 | awk '{print $2}')"
echo "flux: $(flux --version 2>/dev/null || echo 'not installed')"
echo "kind: $(kind --version 2>/dev/null || echo 'not installed')"
echo "podman: $(podman --version 2>/dev/null || echo 'not installed')"
echo "bash: $(bash --version | head -n1)"

echo ""
echo "Setup complete! Remember to run 'source .env' to activate mise for this project."