#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# VM Setup Script: Bootstrap a fresh Ubuntu VM for Node.js app deployment
# Run this ONCE on a new Ubuntu 22.04 VM as a sudo user
#
# Usage:
#   chmod +x setup-vm.sh
#   sudo ./setup-vm.sh
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

APP_DIR="/home/$SUDO_USER/nodejs-devops-app"
DOCKER_COMPOSE_VERSION="v2.24.5"

echo "════════════════════════════════════════════"
echo "  🚀 DevOps VM Bootstrap Setup"
echo "════════════════════════════════════════════"

# ── 1. Update system packages ──────────────────────────────────────────────
echo "[1/6] Updating system packages..."
apt-get update -y && apt-get upgrade -y

# ── 2. Install required utilities ─────────────────────────────────────────
echo "[2/6] Installing utilities..."
apt-get install -y \
    curl \
    wget \
    git \
    ca-certificates \
    gnupg \
    lsb-release \
    ufw

# ── 3. Install Docker Engine ───────────────────────────────────────────────
echo "[3/6] Installing Docker Engine..."

# Remove old versions if any
apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# ── 4. Configure Docker ────────────────────────────────────────────────────
echo "[4/6] Configuring Docker..."

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add current user to docker group (so sudo isn't needed)
usermod -aG docker "$SUDO_USER"

echo "✅ Docker installed: $(docker --version)"
echo "✅ Docker Compose installed: $(docker compose version)"

# ── 5. Configure Firewall ──────────────────────────────────────────────────
echo "[5/6] Configuring firewall..."
ufw allow ssh
ufw allow 3000/tcp    # Node.js app port
ufw allow 80/tcp      # HTTP (optional, for reverse proxy)
ufw allow 443/tcp     # HTTPS (optional, for reverse proxy)
ufw --force enable

echo "✅ Firewall configured:"
ufw status numbered

# ── 6. Create application directory ───────────────────────────────────────
echo "[6/6] Setting up application directory..."
mkdir -p "$APP_DIR"
chown "$SUDO_USER:$SUDO_USER" "$APP_DIR"

echo ""
echo "════════════════════════════════════════════"
echo "  ✅ VM Bootstrap Complete!"
echo "════════════════════════════════════════════"
echo ""
echo "📋 Next Steps:"
echo "   1. Log out and back in for docker group changes to take effect"
echo "   2. Add GitHub Secrets to your repository:"
echo "      VM_HOST           = $(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_VM_IP')"
echo "      VM_USERNAME       = $SUDO_USER"
echo "      VM_SSH_PRIVATE_KEY = (your private SSH key)"
echo "      DOCKERHUB_USERNAME = AmanaJamsheed"
echo "      DOCKERHUB_TOKEN   = (your Docker Hub access token)"
echo ""
echo "   3. Manually run the first deployment:"
echo "      cd $APP_DIR"
echo "      docker compose up -d"
echo ""
echo "   4. GitHub Actions will handle future deployments automatically!"
echo ""
