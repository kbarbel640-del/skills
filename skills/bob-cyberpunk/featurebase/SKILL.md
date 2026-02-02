---
name: featurebase
description: FeatureBase feedback platform — manage support conversations, feature requests, posts, changelogs, surveys, companies, teams, and help center articles via MCP server. Use for reading/triaging support tickets, monitoring new conversations, assigning teams, and tracking feature request activity.
---

# FeatureBase MCP Skill

Access the [FeatureBase](https://featurebase.app) feedback platform via a local MCP server.

## CLI Tool

```bash
fb <tool_name> [key=value ...]
```

The `fb` CLI connects to the FeatureBase MCP server (SSE transport, managed by launchd).

**Location:** `bin/fb` (workspace) or `featurebase-mcp/fb` (source)

## Available Tools

### Boards
```bash
fb list_boards
fb get_board board_id=<id>
```

### Posts (Feature Requests)
```bash
# Params: limit (1-100), cursor, board_id, status_id, tags, q, in_review,
#         sort_by=[createdAt|upvotes|trending|recent], sort_order=[asc|desc]
fb list_posts limit=20 sort_by=createdAt sort_order=desc
fb get_post post_id=<id>
```

### Post Statuses
```bash
fb list_post_statuses
fb get_post_status status_id=<id>
```

### Custom Fields
```bash
fb list_custom_fields
```

### Changelogs
```bash
# Params: changelog_id, q, categories, locale, state=[draft|live|all],
#         start_date, end_date, limit, cursor, sort_by=date, sort_order=[asc|desc]
fb list_changelogs state=live limit=10
```

### Admins & Teams
```bash
fb list_admins
fb get_admin admin_id=<id>
fb list_teams
fb get_team team_id=<id>
```

### Companies
```bash
fb list_companies limit=50
fb get_company company_id=<id>
```

### Surveys
```bash
# Params: limit, cursor, survey_type=[text|link|rating|multiple-choice], is_active
fb list_surveys is_active=true
```

### Help Center
```bash
fb get_help_center
```

### Conversations (Support Tickets)
```bash
fb list_conversations limit=20              # paginated, returns open conversations
fb get_conversation conversation_id=<id>    # includes all message parts
fb assign_conversation_team conversation_id=<id> team_id=<team_id>
fb assign_conversation_admin conversation_id=<id> admin_id=<admin_id>
fb update_conversation_state conversation_id=<id> state=closed  # open|closed|snoozed
```

### Webhooks
```bash
# Params: limit, cursor, status=[active|paused|suspended]
fb list_webhooks status=active
```

## Conversation Triage

For guidance on triaging support conversations into teams, see [references/triage.md](references/triage.md).

## Pagination

Responses include `"nextCursor"` when more results exist. Pass `cursor=<value>` to fetch the next page.

## MCP Server

- **Repo:** `featurebase-mcp/` (source)
- **Transport:** SSE (configurable port)
- **Runtime:** Python 3.12 + FastMCP
- **Managed by:** launchd (recommended)
- **Restart:** `launchctl unload ~/Library/LaunchAgents/com.<name>.featurebase-mcp.plist && launchctl load ~/Library/LaunchAgents/com.<name>.featurebase-mcp.plist`
