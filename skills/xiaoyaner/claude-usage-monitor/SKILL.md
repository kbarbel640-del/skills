---
name: claude-usage-monitor
version: 1.0.0
description: Monitor and analyze Claude subscription usage (Pro/Max 5x/Max 20x/Team) with resource planning and budget optimization.
author: xiaoyaner
---

# Claude Usage Monitor Skill

This skill helps AI assistants monitor Claude subscription usage, analyze consumption patterns, and provide resource planning recommendations for optimal usage distribution.

## Supported Plans

| Plan | Session Limit | Weekly Limit | Reset Period |
|------|---------------|--------------|--------------|
| Free | Limited | N/A | N/A |
| Pro | 1x baseline | Weekly cap | Session: 5h, Weekly: 7d |
| Max 5x | 5x baseline | Weekly cap | Session: 5h, Weekly: 7d |
| Max 20x | 20x baseline | Weekly cap | Session: 5h, Weekly: 7d |
| Team | Variable | Team pool | Session: 5h, Weekly: 7d |

## Usage Query

### Via Browser (Recommended)

Access usage information at: `https://claude.ai/settings/usage`

The page displays:
- **Current session usage** — Percentage used, reset countdown
- **Weekly limit (All models)** — Percentage used, reset date/time
- **Weekly limit (Sonnet only)** — Percentage used, reset date/time
- **Extra usage toggle** — Option to continue beyond limits (additional charges)

### Browser Automation Example

```bash
# Using OpenClaw browser tool
browser action=navigate targetUrl="https://claude.ai/settings/usage" profile=openclaw
browser action=snapshot
```

Parse the snapshot to extract:
- Session usage percentage
- Session reset time remaining
- Weekly usage percentage (All models)
- Weekly usage percentage (Sonnet only)
- Weekly reset date/time

## Resource Planning

### Calculate Daily Budget

Given weekly usage data, calculate optimal daily usage:

```
Daily budget = (100% - current_weekly_usage%) / days_until_reset
```

**Example:**
- Current weekly usage: 10%
- Days until reset: 5
- Daily budget: (100 - 10) / 5 = 18% per day

### Session Management

Session limits reset every 5 hours. For intensive work:

1. Check current session usage before starting
2. If session > 80%, consider waiting for reset
3. Plan heavy tasks for fresh sessions

### Model Selection Strategy

- **Opus (most capable)**: Use for complex reasoning, coding, analysis
- **Sonnet (balanced)**: Daily tasks, has separate weekly quota
- **Haiku (fastest)**: Quick questions, simple tasks

Using Sonnet for routine tasks preserves your "All models" quota for Opus.

## Usage Alerts

### Recommended Thresholds

| Level | Session | Weekly | Action |
|-------|---------|--------|--------|
| 🟢 Normal | < 50% | < 50% | Continue normally |
| 🟡 Caution | 50-80% | 50-70% | Consider pacing |
| 🔴 Warning | > 80% | > 70% | Reduce usage, wait for reset |

### Alert Message Templates

**Session Warning:**
```
⚠️ Session usage at {percentage}%. Resets in {time_remaining}.
Consider waiting for reset or switching to lighter tasks.
```

**Weekly Warning:**
```
⚠️ Weekly usage at {percentage}%. Resets on {reset_date}.
Daily budget remaining: {daily_budget}% per day.
```

## Integration with OpenClaw

### Heartbeat Check

Add to HEARTBEAT.md for periodic monitoring:

```markdown
## Usage Monitor
- Check Claude usage if last check > 4 hours ago
- Alert if session > 80% or weekly > 70%
```

### Cron Job (Daily Summary)

```json
{
  "schedule": { "kind": "cron", "expr": "0 9 * * *", "tz": "Asia/Shanghai" },
  "payload": { 
    "kind": "systemEvent", 
    "text": "Check Claude usage at https://claude.ai/settings/usage and provide a daily summary with remaining budget."
  },
  "sessionTarget": "main"
}
```

## Best Practices

### Maximize Efficiency

1. **Batch similar tasks** — Group related work in single sessions
2. **Use appropriate models** — Don't use Opus for simple questions
3. **Leverage context** — Long conversations are more efficient than many short ones
4. **Use Projects** — Store context in Projects to reduce repetitive input

### Avoid Waste

1. **Don't regenerate unnecessarily** — Each regeneration costs usage
2. **Be specific** — Clear prompts reduce back-and-forth
3. **Check session timing** — Don't start big tasks near session reset if usage is high

### Extra Usage

When limits are reached, you can enable "Extra usage" at:
`https://claude.ai/settings/usage`

This allows continued use with additional per-message charges. Consider:
- Is the task urgent?
- Can it wait for reset?
- Is the cost justified?

## Troubleshooting

### Usage Not Updating

- Click "Refresh usage limits" button on the page
- Wait a few minutes for server sync
- Check if you're logged into the correct account

### Unexpected High Usage

Usage is affected by:
- Message length and complexity
- File/image uploads
- Tool usage (code execution, artifacts)
- Model choice (Opus uses more than Sonnet)

### Reset Time Changed

Reset times are calculated from when your session started, not fixed times. If you see different reset times, this is normal behavior.

## References

- [Understanding usage and length limits](https://support.claude.com/en/articles/11647753-understanding-usage-and-length-limits)
- [What is the Max plan?](https://support.claude.com/en/articles/11049741-what-is-the-max-plan)
- [Extra usage for paid Claude plans](https://support.claude.com/en/articles/12429409-extra-usage-for-paid-claude-plans)
- [Usage limit best practices](https://support.claude.com/en/articles/9797557-usage-limit-best-practices)
