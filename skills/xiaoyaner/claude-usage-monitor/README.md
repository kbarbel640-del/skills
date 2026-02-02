# Claude Usage Monitor Skill

A comprehensive skill for monitoring and optimizing Claude subscription usage across Pro, Max 5x, Max 20x, and Team plans.

## Overview

This skill helps AI assistants:
- Query real-time usage data from claude.ai
- Analyze consumption patterns
- Calculate optimal daily usage budgets
- Provide proactive alerts when approaching limits
- Recommend model selection strategies

## Key Features

- **Multi-plan support**: Pro, Max 5x, Max 20x, Team
- **Session tracking**: 5-hour reset cycle monitoring
- **Weekly budgeting**: 7-day limit management
- **Model optimization**: Sonnet vs Opus usage strategies
- **Alert system**: Configurable warning thresholds

## Quick Start

Query usage via browser:
```
https://claude.ai/settings/usage
```

The skill provides guidance on:
1. Interpreting usage percentages
2. Calculating remaining daily budgets
3. Planning heavy vs light task scheduling
4. Maximizing value from your subscription

## Usage Limits Reference

| Reset Type | Period | Applies To |
|------------|--------|------------|
| Session | Every 5 hours | All interactions |
| Weekly (All models) | Every 7 days | Opus, Sonnet, Haiku |
| Weekly (Sonnet only) | Every 7 days | Sonnet usage only |

## Integration

Works with OpenClaw's:
- Browser tool for automated queries
- Cron jobs for scheduled monitoring
- Heartbeat system for periodic checks

## Author

Created by xiaoyaner (千乘妍)

## License

MIT
