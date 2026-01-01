#!/bin/bash
set -euo pipefail

# -------------------------------
# Colors
# -------------------------------
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

info()  { echo -e "${BLUE}>> $*${RESET}"; }
ok()    { echo -e "${GREEN}✔ $*${RESET}"; }
warn()  { echo -e "${YELLOW}⚠ $*${RESET}"; }
fail()  { echo -e "${RED}✖ $*${RESET}"; exit 1; }

# -------------------------------
# Sanity checks
# -------------------------------
[ "$EUID" -ne 0 ] || fail "Do NOT run this script as root"
command -v curl >/dev/null || fail "curl not installed"
command -v sudo >/dev/null || fail "sudo not installed"

# -------------------------------
# Install Docker
# -------------------------------
info "Installing Docker"
sudo apt-get update -y
sudo apt-get install -y docker.io ca-certificates

sudo systemctl enable --now docker
ok "Docker installed and running"

# -------------------------------
# Docker permissions (NO relogin)
# -------------------------------
info "Configuring Docker socket access for current user"
sudo usermod -aG docker "$USER"

# ACL workaround (immediate effect)
sudo setfacl -m u:"$USER":rw /var/run/docker.sock
ok "Docker permissions applied (no relogin required)"

# Verify Docker access
docker ps >/dev/null 2>&1 || fail "Docker still not accessible"

# -------------------------------
# Install k3d
# -------------------------------
info "Installing k3d"
if command -v k3d >/dev/null; then
  warn "k3d already installed, skipping"
else
  curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi
ok "k3d ready"

# -------------------------------
# Install kubectl (robust)
# -------------------------------
info "Installing kubectl"

KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt || true)"
[ -n "$KUBECTL_VERSION" ] || KUBECTL_VERSION="v1.29.0"

curl -fsSLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

ok "kubectl ${KUBECTL_VERSION} installed"

# -------------------------------
# Final verification
# -------------------------------
info "Verifying installation"
docker --version
k3d version
kubectl version --client

echo
ok "Installation complete"
echo -e "${GREEN}You can now run:${RESET}"
echo "  ./start.sh"
