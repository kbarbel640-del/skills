#!/bin/bash
# OpenClaw Quick Setup - GCP + Tailscale + Brave
# Usage: Set environment variables, then run locally

set -euo pipefail

# === REQUIRED ENVIRONMENT VARIABLES ===
# Export these before running:
#   export OPENCLAW_PROJECT_ID="your-project"
#   export OPENCLAW_USERNAME="your-username"
#   export ANTHROPIC_TOKEN="sk-ant-oat01-..."
#   export BRAVE_API_KEY="your-brave-key"

: "${OPENCLAW_PROJECT_ID:?ERROR: Set OPENCLAW_PROJECT_ID environment variable}"
: "${OPENCLAW_USERNAME:?ERROR: Set OPENCLAW_USERNAME environment variable}"
: "${ANTHROPIC_TOKEN:?ERROR: Set ANTHROPIC_TOKEN environment variable}"
: "${BRAVE_API_KEY:?ERROR: Set BRAVE_API_KEY environment variable}"

ZONE="${OPENCLAW_ZONE:-us-central1-a}"
VM="${OPENCLAW_VM_NAME:-openclaw}"
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/id_ed25519.pub}"

# Validate SSH key exists
if [[ ! -f "$SSH_KEY_PATH" ]]; then
    echo "ERROR: SSH public key not found at $SSH_KEY_PATH" >&2
    exit 1
fi

# === CREATE VM ===
echo "Creating VM ${VM}..."
if ! gcloud compute instances describe "$VM" --project="$OPENCLAW_PROJECT_ID" --zone="$ZONE" &>/dev/null; then
    gcloud compute instances create "$VM" \
        --project="$OPENCLAW_PROJECT_ID" \
        --zone="$ZONE" \
        --machine-type=e2-medium \
        --image-family=debian-12 \
        --image-project=debian-cloud \
        --boot-disk-size=10GB \
        --metadata=ssh-keys="${OPENCLAW_USERNAME}:$(cat "$SSH_KEY_PATH")"
else
    echo "VM ${VM} already exists, skipping creation"
fi

IP=$(gcloud compute instances describe "$VM" \
    --project="$OPENCLAW_PROJECT_ID" \
    --zone="$ZONE" \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

if [[ -z "$IP" ]]; then
    echo "ERROR: Failed to get VM IP address" >&2
    exit 1
fi

echo "VM IP: $IP"
echo "Waiting for SSH to become available..."
for i in {1..30}; do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "${OPENCLAW_USERNAME}@${IP}" "echo 'SSH ready'" &>/dev/null; then
        break
    fi
    echo "  Attempt $i/30..."
    sleep 10
done

# === INSTALL DEPENDENCIES ===
echo "Installing dependencies..."
ssh -o StrictHostKeyChecking=no "${OPENCLAW_USERNAME}@${IP}" "
set -euo pipefail
sudo apt-get update
sudo apt-get install -y git curl ufw jq
"

# === INSTALL TAILSCALE ===
echo "Installing Tailscale..."
ssh "${OPENCLAW_USERNAME}@${IP}" "
set -euo pipefail
if ! command -v tailscale &>/dev/null; then
    curl -fsSL https://tailscale.com/install.sh | sh
fi
"

echo ""
echo "=========================================="
echo "ACTION REQUIRED: Authorize Tailscale"
echo "Run this on the VM and follow the URL:"
echo "  ssh ${OPENCLAW_USERNAME}@${IP} 'sudo tailscale up'"
echo "=========================================="
read -rp "Press enter after authorizing Tailscale..."

# Verify Tailscale is connected
if ! ssh "${OPENCLAW_USERNAME}@${IP}" "tailscale status &>/dev/null"; then
    echo "ERROR: Tailscale not connected. Please run 'sudo tailscale up' on the VM." >&2
    exit 1
fi

# === CONFIGURE UFW ===
echo "Configuring firewall..."
ssh "${OPENCLAW_USERNAME}@${IP}" "
set -euo pipefail
sudo ufw allow 22/tcp
sudo ufw allow in on tailscale0
echo 'y' | sudo ufw enable || true
"

# === FIX DNS ===
echo "Fixing DNS resolution..."
ssh "${OPENCLAW_USERNAME}@${IP}" "
if ! grep -q '8.8.8.8' /etc/resolv.conf; then
    echo 'nameserver 8.8.8.8' | sudo tee -a /etc/resolv.conf
fi
"

# === INSTALL NODE.JS VIA NVM ===
echo "Installing Node.js 22 via nvm..."
ssh "${OPENCLAW_USERNAME}@${IP}" '
set -euo pipefail
export NVM_DIR="$HOME/.nvm"
if [[ ! -d "$NVM_DIR" ]]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi
source "$NVM_DIR/nvm.sh"
if ! node --version 2>/dev/null | grep -q "v22"; then
    nvm install 22
    nvm alias default 22
fi
echo "Node.js version: $(node --version)"
'

# === INSTALL OPENCLAW ===
echo "Installing OpenClaw..."
ssh "${OPENCLAW_USERNAME}@${IP}" '
set -euo pipefail
source "$HOME/.nvm/nvm.sh"
if ! command -v openclaw &>/dev/null; then
    npm install -g openclaw@latest
fi
openclaw --version
'

# === CONFIGURE OPENCLAW (credentials passed securely) ===
echo "Configuring OpenClaw..."
ssh "${OPENCLAW_USERNAME}@${IP}" "
set -euo pipefail
source \"\$HOME/.nvm/nvm.sh\"
openclaw onboard \
    --non-interactive \
    --accept-risk \
    --auth-choice token \
    --token-provider anthropic \
    --token \"\$(cat)\" \
    --gateway-bind loopback \
    --install-daemon
" <<< "$ANTHROPIC_TOKEN"

# === ADD BRAVE API KEY (passed securely via stdin) ===
echo "Configuring Brave Search..."
ssh "${OPENCLAW_USERNAME}@${IP}" "
set -euo pipefail
mkdir -p ~/.config/systemd/user/openclaw-gateway.service.d
cat > ~/.config/systemd/user/openclaw-gateway.service.d/brave.conf << EOF
[Service]
Environment=\"BRAVE_API_KEY=\$(cat)\"
EOF
chmod 600 ~/.config/systemd/user/openclaw-gateway.service.d/brave.conf
systemctl --user daemon-reload
" <<< "$BRAVE_API_KEY"

# === ENABLE TAILSCALE AUTH ===
echo "Enabling Tailscale authentication..."
ssh "${OPENCLAW_USERNAME}@${IP}" '
set -euo pipefail
source "$HOME/.nvm/nvm.sh"
CONFIG="$HOME/.openclaw/openclaw.json"
if [[ -f "$CONFIG" ]]; then
    jq ".gateway.auth.allowTailscale = true" "$CONFIG" > "${CONFIG}.tmp"
    mv "${CONFIG}.tmp" "$CONFIG"
    chmod 600 "$CONFIG"
fi
openclaw gateway restart
'

# === ENABLE TAILSCALE SERVE ===
echo "Enabling Tailscale Serve..."
SERVE_OUTPUT=$(ssh "${OPENCLAW_USERNAME}@${IP}" "sudo tailscale serve --bg 18789 2>&1" || true)
echo "$SERVE_OUTPUT"

if echo "$SERVE_OUTPUT" | grep -q "not enabled"; then
    echo ""
    echo "=========================================="
    echo "ACTION REQUIRED: Enable Tailscale Serve"
    echo "Visit the URL shown above to enable Serve"
    echo "=========================================="
    read -rp "Press enter after enabling Tailscale Serve..."
    ssh "${OPENCLAW_USERNAME}@${IP}" "sudo tailscale serve --bg 18789"
fi

# === SHOW STATUS ===
echo ""
echo "=========================================="
echo "SETUP COMPLETE"
echo "=========================================="
ssh "${OPENCLAW_USERNAME}@${IP}" "tailscale serve status"

echo ""
echo "After first browser access, approve pairing with:"
echo "  ssh ${OPENCLAW_USERNAME}@${IP} 'source ~/.nvm/nvm.sh && openclaw devices list'"
echo "  ssh ${OPENCLAW_USERNAME}@${IP} 'source ~/.nvm/nvm.sh && openclaw devices approve <REQUEST_ID>'"
