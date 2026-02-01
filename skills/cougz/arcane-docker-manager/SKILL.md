---
name: Arcane Docker Manager
description: Comprehensive Docker container management via Arcane API. Manage containers, projects, images, networks, volumes across multiple Docker hosts.

---

# Arcane Docker Manager

## Setup

Configure credentials in `~/.openclaw/.env`:

```bash
ARCANE_BASE_URL=https://your-arcane-instance.com/api
ARCANE_API_KEY=arc_your_api_key_here
```

Load variables: `source ~/.openclaw/.env`

## Core Concept

Arcane uses **environment-scoped architecture**. Most operations require an environment ID:

```bash
# List environments first
ENV_ID=$(curl -s "$ARCANE_BASE_URL/environments" \
  -H "X-API-Key: $ARCANE_API_KEY" \
  | jq -r '.data[0].id')

# Use ENV_ID in subsequent calls
curl "$ARCANE_BASE_URL/environments/$ENV_ID/containers" \
  -H "X-API-Key: $ARCANE_API_KEY"
```

## API Quick Reference

```
/environments
  /{id}/containers          → List/start/stop/restart containers
  /{id}/projects            → Compose stacks: up/down/pull/restart
  /{id}/images             → List/pull/prune images
  /{id}/networks            → List/prune networks
  /{id}/volumes            → List/prune volumes
  /{id}/system/health       → Check health
  /{id}/system/prune       → Clean all unused resources
/templates                 → Global deployment templates
```

## Environments

```bash
# List all
curl "$ARCANE_BASE_URL/environments" -H "X-API-Key: $ARCANE_API_KEY"

# Get details
curl "$ARCANE_BASE_URL/environments/$ENV_ID" -H "X-API-Key: $ARCANE_API_KEY"

# Test connection
curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/test" \
  -H "X-API-Key: $ARCANE_API_KEY"

# Health check
curl "$ARCANE_BASE_URL/environments/$ENV_ID/system/health" \
  -H "X-API-Key: $ARCANE_API_KEY"
```

## Containers

```bash
# List containers
curl "$ARCANE_BASE_URL/environments/$ENV_ID/containers" \
  -H "X-API-Key: $ARCANE_API_KEY"

# Get counts
curl "$ARCANE_BASE_URL/environments/$ENV_ID/containers/counts" \
  -H "X-API-Key: $ARCANE_API_KEY"

# Container operations
curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/containers/$CID/start" \
  -H "X-API-Key: $ARCANE_API_KEY"

curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/containers/$CID/stop" \
  -H "X-API-Key: $ARCANE_API_KEY"

curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/containers/$CID/restart" \
  -H "X-API-Key: $ARCANE_API_KEY"

# Get logs
curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/containers/$CID/logs" \
  -H "X-API-Key: $ARCANE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"tail": "100"}'

# Bulk operations
curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/system/containers/start-all" \
  -H "X-API-Key: $ARCANE_API_KEY"
```

## Projects (Compose Stacks)

```bash
# List projects
curl "$ARCANE_BASE_URL/environments/$ENV_ID/projects" \
  -H "X-API-Key: $ARCANE_API_KEY"

# Project operations
curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/projects/$PID/up" \
  -H "X-API-Key: $ARCANE_API_KEY"

curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/projects/$PID/down" \
  -H "X-API-Key: $ARCANE_API_KEY"

curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/projects/$PID/restart" \
  -H "X-API-Key: $ARCANE_API_KEY"

curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/projects/$PID/pull" \
  -H "X-API-Key: $ARCANE_API_KEY"

curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/projects/$PID/redeploy" \
  -H "X-API-Key: $ARCANE_API_KEY"

curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/projects/$PID/destroy" \
  -H "X-API-Key: $ARCANE_API_KEY"
```

## Images

```bash
# List images
curl "$ARCANE_BASE_URL/environments/$ENV_ID/images" \
  -H "X-API-Key: $ARCANE_API_KEY"

# Pull image
curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/images/pull" \
  -H "X-API-Key: $ARCANE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"image": "nginx:latest"}'

# Prune unused
curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/images/prune" \
  -H "X-API-Key: $ARCANE_API_KEY"

# Check for updates
curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/image-updates/check-all" \
  -H "X-API-Key: $ARCANE_API_KEY"
```

## Networks & Volumes

```bash
# Networks
curl "$ARCANE_BASE_URL/environments/$ENV_ID/networks" \
  -H "X-API-Key: $ARCANE_API_KEY"

curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/networks/prune" \
  -H "X-API-Key: $ARCANE_API_KEY"

# Volumes
curl "$ARCANE_BASE_URL/environments/$ENV_ID/volumes" \
  -H "X-API-Key: $ARCANE_API_KEY"

curl "$ARCANE_BASE_URL/environments/$ENV_ID/volumes/prune" \
  -H "X-API-Key: $ARCANE_API_KEY"

curl "$ARCANE_BASE_URL/environments/$ENV_ID/volumes/$VOLUME_NAME/usage" \
  -H "X-API-Key: $ARCANE_API_KEY"
```

## Templates

Templates are **global** (not environment-scoped):

```bash
# List templates
curl "$ARCANE_BASE_URL/templates" -H "X-API-Key: $ARCANE_API_KEY"

# Get global variables
curl "$ARCANE_BASE_URL/templates/global-variables" \
  -H "X-API-Key: $ARCANE_API_KEY"

# Update global variables
curl -X PUT "$ARCANE_BASE_URL/templates/global-variables" \
  -H "X-API-Key: $ARCANE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"GLOBAL_DOMAIN": "example.com"}'
```

## GitOps

```bash
# List syncs
curl "$ARCANE_BASE_URL/environments/$ENV_ID/gitops-syncs" \
  -H "X-API-Key: $ARCANE_API_KEY"

# Create sync
curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/gitops-syncs" \
  -H "X-API-Key: $ARCANE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "prod-sync",
    "repositoryUrl": "https://github.com/user/infra.git",
    "branch": "main",
    "path": "/compose"
  }'

# Trigger sync
curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/gitops-syncs/$SYNC_ID/sync" \
  -H "X-API-Key: $ARCANE_API_KEY"

# Check status
curl "$ARCANE_BASE_URL/environments/$ENV_ID/gitops-syncs/$SYNC_ID/status" \
  -H "X-API-Key: $ARCANE_API_KEY"
```

## System Operations

```bash
# System-wide prune
curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/system/prune" \
  -H "X-API-Key: $ARCANE_API_KEY"

# Get Docker info
curl "$ARCANE_BASE_URL/environments/$ENV_ID/system/docker/info" \
  -H "X-API-Key: $ARCANE_API_KEY"

# Get version
curl "$ARCANE_BASE_URL/version" -H "X-API-Key: $ARCANE_API_KEY"
```

## Common Workflows

**Update and restart container:**
```bash
ENV_ID="0"
PROJECT_ID="your-project-id"

curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/projects/$PROJECT_ID/pull" \
  -H "X-API-Key: $ARCANE_API_KEY"

curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/projects/$PROJECT_ID/restart" \
  -H "X-API-Key: $ARCANE_API_KEY"
```

**Clean up all unused resources:**
```bash
ENV_ID="0"

curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/images/prune" \
  -H "X-API-Key: $ARCANE_API_KEY"

curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/volumes/prune" \
  -H "X-API-Key: $ARCANE_API_KEY"

# Or all at once
curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/system/prune" \
  -H "X-API-Key: $ARCANE_API_KEY"
```

**Deploy from template:**
```bash
TEMPLATE_ID="your-template-id"

curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/projects" \
  -H "X-API-Key: $ARCANE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "production-app",
    "templateId": "'"$TEMPLATE_ID"'",
    "envVars": {"VERSION": "v1.2.3", "PORT": "8080"}
  }'

curl -X POST "$ARCANE_BASE_URL/environments/$ENV_ID/projects/$PROJECT_ID/up" \
  -H "X-API-Key: $ARCANE_API_KEY"
```

## Best Practices

1. **Always list environments first** and store ENV_ID
2. **Test connectivity** before deploying
3. **Use meaningful environment names** (prod/staging/dev)
4. **Monitor system health** regularly
5. **Prune unused resources** periodically
6. **Use templates** for reusable configurations
7. **Use GitOps** for declarative deployments
8. **Set up notifications** for important events

## Troubleshooting

**Connection failed**: Test with `POST /environments/{id}/test`

**Auth failed**: Verify API key is correct and not expired

**Container won't start**: Check image exists, no port conflicts, system health

**Project deployment failed**: Validate compose syntax, check template variables, verify images

**Resource not found (404)**: Verify ENV_ID and resource ID

## Notes

- Most Docker operations require ENV_ID
- Timestamps are ISO 8601 (UTC)
- Container IDs: full or short (first 12 chars)
- Project names must be unique within environment
- Templates are global, projects are per-environment

---

**Version:** 1.13.2+
