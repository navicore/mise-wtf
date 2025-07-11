# Mac K8s Lab Setup

A hybrid mise/brew setup for running Kubernetes labs on macOS using podman + kind.

## Why This Approach?

- **Docker Desktop Issues**: License management bugs make it unusable in enterprise environments
- **Podman + Kind**: Open source alternative that works well on macOS
- **Mise for Most Tools**: Handles versioning for node, java, go, python, kubectl, flux, kind
- **Brew for Specific Tools**: Only podman and bash5 due to plugin limitations

## Prerequisites

- macOS (Intel or Apple Silicon)
- Homebrew installed
- Internet connection for downloading tools

## Quick Start

```bash
# First time setup
./setup.sh

# Activate mise for this project
source .env
```

This will:
1. Install mise (if not already installed)
2. Install development tools via mise
3. Install podman and bash via brew
4. Verify installations

## Tools Included

| Tool | Version | Installed Via | Purpose |
|------|---------|---------------|---------|
| Node.js | 24+ | mise | JavaScript runtime |
| Java | 17 | mise | JVM for various tools |
| Go | 1.23 | mise | Go development |
| Python | 3.12 | mise | Python development |
| kubectl | latest | mise | Kubernetes CLI |
| Flux | latest | mise | GitOps for Kubernetes |
| kind | latest | mise | Kubernetes in Docker |
| Podman | 5.5.2+ | brew | Container runtime (Docker alternative) |
| Bash | 5+ | brew | Modern bash features |

## Project Structure

- `.mise.toml` - Tool versions managed by mise
- `.env` - Project-specific environment (activates mise, sets KUBECONFIG, etc.)
- `setup.sh` - Initial setup script (respects your dotfiles)
- `README.md` - This file

## Philosophy

- **No Dotfile Pollution**: Setup script never modifies your shell configs
- **Project Isolation**: Use `source .env` to activate tools only when working on this project
- **Explicit Over Implicit**: You choose when and how to activate mise

## Next Steps

Ready to set up the K8s lab components!