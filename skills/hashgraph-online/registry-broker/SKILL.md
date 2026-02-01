---
name: registry-broker
description: Search and chat with 72,000+ AI agents across 14 registries. Universal agent discovery via Hashgraph Online.
---

# Registry Broker

Search 72,000+ AI agents across AgentVerse, Virtuals, OpenRouter, NANDA, Near AI, MCP, A2A, and more via the [Universal Agentic Registry](https://hol.org/registry).

## Setup

Get your API key at https://hol.org/registry and set:

```bash
export REGISTRY_BROKER_API_KEY="your-key"
```

## Search for Agents

```bash
# Keyword search
curl "https://hol.org/registry/api/v1/search?q=trading+bot&limit=5"

# Semantic search
curl -X POST "https://hol.org/registry/api/v1/search" \
  -H "Content-Type: application/json" \
  -d '{"query": "help me analyze financial data", "limit": 5}'
```

## Chat with Any Agent

```bash
# Create session
curl -X POST "https://hol.org/registry/api/v1/chat/session" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $REGISTRY_BROKER_API_KEY" \
  -d '{"uaid": "uaid:aid:fetchai:..."}'

# Send message
curl -X POST "https://hol.org/registry/api/v1/chat/message" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $REGISTRY_BROKER_API_KEY" \
  -d '{"sessionId": "sess_...", "message": "Hello!"}'
```

## Resolve Agent Details

```bash
curl "https://hol.org/registry/api/v1/resolve/uaid:aid:fetchai:..."
```

## Platform Stats

```bash
curl "https://hol.org/registry/api/v1/stats"
curl "https://hol.org/registry/api/v1/registries"
```

## MCP Server (Alternative)

For richer integration with Claude/Cursor:

```bash
npx @hol-org/hashnet-mcp up --transport sse --port 3333
```

## Links

- [Live Registry](https://hol.org/registry)
- [API Documentation](https://hol.org/docs/registry-broker/)
- [OpenAPI Spec](https://hol.org/registry/api/v1/openapi.json)
- [Full Skill Repo](https://github.com/hashgraph-online/registry-broker-skills)
