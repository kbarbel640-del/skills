---
name: agentns
description: Register and manage domains for AI agents via AgentNS.xyz - the first ICANN registrar built for autonomous agents. Use for domain registration, DNS management, WHOIS privacy, and domain renewal. Supports 400+ TLDs (.com, .io, .ai, .net, .xyz, .dev, and more) with USDC payments on Base blockchain. Trigger when user mentions domain registration, buying domains, DNS management, or needs a web presence for their agent or project.
metadata:
  homepage: https://agentns.xyz
  twitter: https://x.com/AgentNSxyz
  docs: https://agentns.xyz/docs
---

# AgentNS - Domain Registration for AI Agents

Register and manage domains via [AgentNS.xyz](https://agentns.xyz) - the first ICANN domain registrar built for autonomous agents.

## Quick Start

```bash
# Search for available domains (checks 20 popular TLDs)
./scripts/search-domain.sh myagent

# Check specific domain (any of 400+ TLDs)
curl -X POST https://agentns.xyz/domains/check \
  -H "Content-Type: application/json" \
  -d '{"domain": "myagent.xyz"}'

# Buy domain (full workflow)
python scripts/buy_domain.py myagent.xyz
```

## Features

- **400+ TLDs**: Register any ICANN TLD
  - Quick search across 20 popular: .com, .io, .ai, .net, .co, .xyz, .dev, .app, .org, .tech, .club, .online, .site, .info, .me, .biz, .us, .cc, .tv, .gg
  - Or check any of 400+ directly via API
- **USDC Payments**: EIP-3009 gasless signatures on Base blockchain
- **Wallet Auth**: Sign-In with Ethereum (SIWE) - no email/password needed
- **Free WHOIS Privacy**: Included on all domains
- **Free DNS Hosting**: 100 records per domain (A, AAAA, CNAME, MX, TXT, SRV, CAA)
- **Full API Control**: Manage everything programmatically

## Pricing

- **Domain cost varies by TLD** (NameSilo cost + 20% markup, minimum $4):
  - .com from ~$11 USDC
  - .io from ~$32 USDC
  - .ai from ~$89 USDC
  - .xyz from ~$12 USDC
- **No platform fees**
- **WHOIS privacy + DNS hosting included free**

## Authentication Flow

1. Get nonce: `GET /auth/nonce`
2. Sign SIWE message (EIP-4361) with your wallet
3. Verify & get JWT: `POST /auth/verify`
4. Use JWT in `Authorization: Bearer <token>` header

See `scripts/buy_domain.py` for complete implementation.

## Common Use Cases

### 1. Search Domain Availability

```bash
# Quick search across 20 popular TLDs
./scripts/search-domain.sh myproject

# Check specific domain
curl -X POST https://agentns.xyz/domains/check \
  -d '{"domain": "myproject.xyz"}'
```

### 2. Register a Domain

Prerequisites:
- Ethereum wallet with USDC on Base network
- ICANN registrant profile (created automatically)

```bash
# Full autonomous purchase
python scripts/buy_domain.py myagent.xyz

# Or check only
python scripts/buy_domain.py myagent.xyz --check-only
```

The script handles:
- Wallet auth (SIWE)
- Registrant profile creation
- x402 payment signing
- Domain registration

### 3. Manage DNS Records

```bash
# List DNS records
curl -X GET https://agentns.xyz/domains/myagent.xyz/dns \
  -H "Authorization: Bearer $TOKEN"

# Add A record
curl -X POST https://agentns.xyz/domains/myagent.xyz/dns \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"type": "A", "host": "@", "value": "1.2.3.4", "ttl": 3600}'

# Update record
curl -X PUT https://agentns.xyz/domains/myagent.xyz/dns/12345 \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"value": "1.2.3.5"}'
```

### 4. Change Nameservers

```bash
curl -X PUT https://agentns.xyz/domains/myagent.xyz/nameservers \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"nameservers": ["ns1.cloudflare.com", "ns2.cloudflare.com"]}'
```

## Payment Protocol

AgentNS uses **x402** (HTTP 402 Payment Required) with **EIP-3009** USDC authorization:

1. First request returns `402 Payment Required`
2. Response includes `X-PAYMENT-REQUIRED` header with payment details
3. Sign EIP-3009 `transferWithAuthorization` 
4. Resubmit with `X-PAYMENT` header
5. Payment settles atomically with registration

**USDC Contract:** `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` (Base)
**Chain ID:** 8453 (Base mainnet)

## API Endpoints

| Endpoint | Auth | Rate Limit | Description |
|----------|------|------------|-------------|
| `GET /health` | No | - | Health check |
| `POST /domains/check` | No | 30/min | Check single domain |
| `POST /domains/search` | No | 10/min | Search 20 popular TLDs |
| `GET /auth/nonce` | No | 10/min | Get SIWE nonce |
| `POST /auth/verify` | No | - | Verify signature → JWT |
| `POST /registrant` | JWT | - | Create profile |
| `POST /domains/register` | JWT + x402 | - | Register domain |
| `GET /domains` | JWT | - | List owned domains |
| `GET /domains/{name}/dns` | JWT | - | List DNS records |
| `POST /domains/{name}/dns` | JWT | - | Add DNS record |
| `PUT /domains/{name}/dns/{id}` | JWT | - | Update DNS record |
| `DELETE /domains/{name}/dns/{id}` | JWT | - | Delete DNS record |
| `PUT /domains/{name}/nameservers` | JWT | - | Change nameservers |

## Scripts Included

### buy_domain.py
Complete autonomous domain purchase workflow with SIWE auth and x402 payment.

**Usage:**
```bash
python scripts/buy_domain.py myagent.xyz
python scripts/buy_domain.py myagent.xyz --years 2
python scripts/buy_domain.py myagent.xyz --check-only
```

**Requirements:**
- Python packages: `httpx`, `eth-account`, `siwe`
- USDC on Base network (fund the auto-generated wallet)

### payment_utils.py
Shared utilities for wallet management and EIP-3009 signing.

### search-domain.sh
Quick domain search across 20 popular TLDs.

## Security Notes

- Wallet signatures required for all transactions
- USDC payment settles atomically with registration
- WHOIS privacy enabled by default
- Full ownership control via wallet
- No email or password required

## References

- **Website:** https://agentns.xyz
- **Agent Docs:** https://agentns.xyz/howtoagents.md
- **API Docs:** https://agentns.xyz/docs
- **Twitter:** https://x.com/AgentNSxyz

## Support

For issues or questions: [@AgentNSxyz](https://x.com/AgentNSxyz) on X
