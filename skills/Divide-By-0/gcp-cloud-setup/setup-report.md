# OpenClaw Cloud Setup Report

## Summary
Successfully deployed OpenClaw 2026.2.1 on GCP with Tailscale access and Brave Search integration.

---

## What Worked

### 1. VM Sizing
- **e2-medium (2 vCPU, 4GB RAM)** is the minimum viable size
- e2-micro (1GB) caused OOM crashes during npm install

### 2. Node.js via nvm
- nvm reliably installed Node.js 22 when nodesource failed
- Required adding `8.8.8.8` to `/etc/resolv.conf` after Tailscale took over DNS

### 3. Non-Interactive Onboarding
```bash
# Token passed via stdin to avoid shell history exposure
openclaw onboard \
  --non-interactive \
  --accept-risk \
  --auth-choice token \
  --token-provider anthropic \
  --token "$(cat)" \
  --gateway-bind loopback \
  --install-daemon <<< "$ANTHROPIC_TOKEN"
```

### 4. Brave API Key via systemd drop-in
```bash
mkdir -p ~/.config/systemd/user/openclaw-gateway.service.d
# Write config with restricted permissions
cat > ~/.config/systemd/user/openclaw-gateway.service.d/brave.conf << EOF
[Service]
Environment="BRAVE_API_KEY=${BRAVE_API_KEY}"
EOF
chmod 600 ~/.config/systemd/user/openclaw-gateway.service.d/brave.conf
systemctl --user daemon-reload
openclaw gateway restart
```

### 5. Tailscale Serve
```bash
sudo tailscale serve --bg 18789
```
- Required enabling Serve in Tailscale admin first via the URL it prints

### 6. Tailscale Identity
```bash
CONFIG="$HOME/.openclaw/openclaw.json"
jq '.gateway.auth.allowTailscale = true' "$CONFIG" > "${CONFIG}.tmp"
mv "${CONFIG}.tmp" "$CONFIG"
chmod 600 "$CONFIG"
openclaw gateway restart
```

### 7. Device Pairing
```bash
openclaw devices list        # Find pending request ID
openclaw devices approve <REQUEST_ID>
```

---

## What Didn't Work

### 1. e2-micro VM
- 1GB RAM insufficient; VM became unresponsive during npm install
- **Fix:** Use e2-medium or larger

### 2. Nodesource for Node.js 22
- apt lock conflicts, connection issues
- **Fix:** Use nvm instead

### 3. Adding Brave key to openclaw.json directly
- Tried `web.search`, `web.braveApiKey` - all rejected as unknown keys
- **Fix:** Use environment variable via systemd drop-in

### 4. DNS after Tailscale
- Tailscale overwrites `/etc/resolv.conf` with MagicDNS (100.100.100.100)
- External domains like `raw.githubusercontent.com` failed to resolve
- **Fix:** `echo 'nameserver 8.8.8.8' | sudo tee -a /etc/resolv.conf`

### 5. `openclaw configure --section web --non-interactive`
- Flag doesn't exist; configure is interactive-only
- **Fix:** Use environment variable approach

---

## Security Considerations

1. **Credential Handling:**
   - Never pass tokens as command-line arguments (visible in `ps`, shell history)
   - Use environment variables or stdin (`<<< "$TOKEN"`)
   - Set restrictive permissions on credential files (`chmod 600`)

2. **File Permissions:**
   - `~/.openclaw/openclaw.json` should be `600`
   - systemd drop-in files with secrets should be `600`
   - `~/.openclaw/credentials/` should be `700`

3. **Network Security:**
   - UFW configured to allow only SSH (22/tcp) and Tailscale interface
   - Gateway binds to loopback only; exposed via Tailscale Serve
   - One-directional Tailscale ACL prevents server from reaching other devices

---

## Complete Working Command Sequence

See `openclaw-quick-setup.sh` for a production-ready script.

### Prerequisites
```bash
# Set environment variables (never hardcode in scripts)
export OPENCLAW_PROJECT_ID="your-project"
export OPENCLAW_USERNAME="your-username"
export ANTHROPIC_TOKEN="sk-ant-oat01-..."  # From secure source
export BRAVE_API_KEY="..."                  # From secure source
```

### Manual Steps Summary

```bash
# 1. Create VM (e2-medium minimum)
gcloud compute instances create openclaw-server \
  --project="$OPENCLAW_PROJECT_ID" \
  --zone=us-central1-a \
  --machine-type=e2-medium \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --boot-disk-size=10GB \
  --metadata=ssh-keys="${OPENCLAW_USERNAME}:$(cat ~/.ssh/id_ed25519.pub)"

# 2. Get IP and wait for SSH
IP=$(gcloud compute instances describe openclaw-server \
  --project="$OPENCLAW_PROJECT_ID" \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

# 3. Install dependencies
ssh "${OPENCLAW_USERNAME}@${IP}" "sudo apt-get update && sudo apt-get install -y git curl ufw jq"

# 4. Install and authorize Tailscale
ssh "${OPENCLAW_USERNAME}@${IP}" "curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up"

# 5. Configure UFW
ssh "${OPENCLAW_USERNAME}@${IP}" "sudo ufw allow 22/tcp && sudo ufw allow in on tailscale0 && echo 'y' | sudo ufw enable"

# 6. Fix DNS
ssh "${OPENCLAW_USERNAME}@${IP}" "echo 'nameserver 8.8.8.8' | sudo tee -a /etc/resolv.conf"

# 7. Install Node.js 22 via nvm
ssh "${OPENCLAW_USERNAME}@${IP}" 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && source ~/.nvm/nvm.sh && nvm install 22'

# 8. Install OpenClaw
ssh "${OPENCLAW_USERNAME}@${IP}" 'source ~/.nvm/nvm.sh && npm install -g openclaw@latest'

# 9. Configure OpenClaw (token via stdin)
ssh "${OPENCLAW_USERNAME}@${IP}" 'source ~/.nvm/nvm.sh && openclaw onboard --non-interactive --accept-risk --auth-choice token --token-provider anthropic --token "$(cat)" --gateway-bind loopback --install-daemon' <<< "$ANTHROPIC_TOKEN"

# 10. Add Brave API key
ssh "${OPENCLAW_USERNAME}@${IP}" "mkdir -p ~/.config/systemd/user/openclaw-gateway.service.d && cat > ~/.config/systemd/user/openclaw-gateway.service.d/brave.conf << EOF
[Service]
Environment=\"BRAVE_API_KEY=\$(cat)\"
EOF
chmod 600 ~/.config/systemd/user/openclaw-gateway.service.d/brave.conf
systemctl --user daemon-reload" <<< "$BRAVE_API_KEY"

# 11. Enable Tailscale auth
ssh "${OPENCLAW_USERNAME}@${IP}" 'source ~/.nvm/nvm.sh && jq ".gateway.auth.allowTailscale = true" ~/.openclaw/openclaw.json > /tmp/oc.json && mv /tmp/oc.json ~/.openclaw/openclaw.json && chmod 600 ~/.openclaw/openclaw.json && openclaw gateway restart'

# 12. Enable Tailscale Serve
ssh "${OPENCLAW_USERNAME}@${IP}" "sudo tailscale serve --bg 18789"

# 13. Get dashboard URL
ssh "${OPENCLAW_USERNAME}@${IP}" "tailscale serve status"

# 14. After first browser access, approve pairing
ssh "${OPENCLAW_USERNAME}@${IP}" 'source ~/.nvm/nvm.sh && openclaw devices list'
ssh "${OPENCLAW_USERNAME}@${IP}" 'source ~/.nvm/nvm.sh && openclaw devices approve <REQUEST_ID>'
```

---

## Environment Summary

| Component | Value |
|-----------|-------|
| VM | e2-medium (2 vCPU, 4GB RAM) |
| OS | Debian 12 |
| Node.js | v22.x via nvm |
| OpenClaw | 2026.2.1 |
| Gateway Port | 18789 |
| Access | Tailscale Serve (HTTPS) |
| Auth | Anthropic token + Tailscale identity |
| Web Search | Brave API via env var |

---

## Tailscale ACL (Optional Security Hardening)

Apply in Tailscale admin → Access Controls to prevent the server from reaching other devices:

```json
{
  "tagOwners": {
    "tag:openclaw": ["autogroup:admin"]
  },
  "acls": [
    {
      "action": "accept",
      "src": ["autogroup:member"],
      "dst": ["tag:openclaw:*"]
    }
  ]
}
```

Then tag the VM: Machines → small-vm → Edit tags → add `tag:openclaw`
