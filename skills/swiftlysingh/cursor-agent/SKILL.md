---
name: cursor-agent
version: 2.1.0
description: A comprehensive skill for using the Cursor CLI agent for various software engineering tasks (updated for 2026 features, includes tmux automation guide).
author: Pushpinder Pal Singh
---

# Cursor CLI Agent Skill

This skill provides a comprehensive guide and set of workflows for utilizing the Cursor CLI tool, including all features from the January 2026 update.

## Installation

### Standard Installation (macOS, Linux, Windows WSL)

```bash
curl https://cursor.com/install -fsS | bash
```

### Homebrew (macOS only)

```bash
brew install --cask cursor-cli
```

### Post-Installation Setup

**macOS:**
- Add to PATH in `~/.zshrc` (zsh) or `~/.bashrc` (bash):
  ```bash
  export PATH="$HOME/.local/bin:$PATH"
  ```
- Restart terminal or run `source ~/.zshrc` (or `~/.bashrc`)
- Requires macOS 10.15 or later
- Works on both Intel and Apple Silicon Macs

**Linux/Ubuntu:**
- Restart your terminal or source your shell config
- Verify with `agent --version`

**Both platforms:**
- Commands: `agent` (primary) and `cursor-agent` (backward compatible)
- Verify installation: `agent --version` or `cursor-agent --version`

## Authentication

Authenticate via browser:

```bash
agent login
```

Or use API key:

```bash
export CURSOR_API_KEY=your_api_key_here
```

## Update

Keep your CLI up to date:

```bash
agent update
# or
agent upgrade
```

## Commands

### Interactive Mode

Start an interactive session with the agent:

```bash
agent
```

Start with an initial prompt:

```bash
agent "Add error handling to this API"
```

**Backward compatibility:** `cursor-agent` still works but `agent` is now the primary command.

### Model Switching

List all available models:

```bash
agent models
# or
agent --list-models
```

Use a specific model:

```bash
agent --model gpt-5
```

Switch models during a session:

```
/models
```

### Session Management

Manage your agent sessions:

- **List sessions:** `agent ls`
- **Resume most recent:** `agent resume`
- **Resume specific session:** `agent --resume="[chat-id]"`

### Context Selection

Include specific files or folders in the conversation:

```
@filename.ts
@src/components/
```

### Slash Commands

Available during interactive sessions:

- **`/models`** - Switch between AI models interactively
- **`/compress`** - Summarize conversation and free up context window
- **`/rules`** - Create and edit rules directly from CLI
- **`/commands`** - Create and modify custom commands
- **`/mcp enable [server-name]`** - Enable an MCP server
- **`/mcp disable [server-name]`** - Disable an MCP server

### Keyboard Shortcuts

- **`Shift+Enter`** - Add newlines for multi-line prompts
- **`Ctrl+D`** - Exit CLI (requires double-press for safety)
- **`Ctrl+R`** - Review changes (press `i` for instructions, navigate with arrow keys)
- **`ArrowUp`** - Cycle through previous messages

### Non-interactive / CI Mode

Run the agent in a non-interactive mode, suitable for CI/CD pipelines:

```bash
agent -p 'Run tests and report coverage'
# or
agent --print 'Refactor this file to use async/await'
```

**Output formats:**

```bash
# Plain text (default)
agent -p 'Analyze code' --output-format text

# Structured JSON
agent -p 'Find bugs' --output-format json

# Real-time streaming JSON
agent -p 'Run tests' --output-format stream-json --stream-partial-output
```

**Force mode (auto-apply changes without confirmation):**

```bash
agent -p 'Fix all linting errors' --force
```

**Media support:**

```bash
agent -p 'Analyze this screenshot: screenshot.png'
```

### ⚠️ Using with AI Agents / Automation (tmux required)

**CRITICAL:** When running Cursor CLI from automated environments (AI agents, scripts, subprocess calls), the CLI requires a real TTY. Direct execution will hang indefinitely.

**The Solution: Use tmux + `-p` mode (recommended)**

The `-p` (print) mode is ideal for automation:
- Non-interactive output (no TUI)
- Clean text/JSON output
- Automatically exits when complete

```bash
# 1. Install tmux if not available
sudo apt install tmux  # Ubuntu/Debian
brew install tmux      # macOS

# 2. Create a tmux session
tmux kill-session -t cursor 2>/dev/null || true
tmux new-session -d -s cursor

# 3. Run Cursor agent with -p mode
tmux send-keys -t cursor "cd /path/to/project && agent -p 'Your task here' --output-format text" Enter

# 4. Handle workspace trust prompt (first run only)
sleep 3
tmux send-keys -t cursor "a"  # Trust workspace

# 5. Smart wait for completion (detect shell prompt)
while true; do
  last_line=$(tmux capture-pane -t cursor -p | grep -v '^$' | tail -1)
  if echo "$last_line" | grep -qE '(\$|%)\s*$' && ! echo "$last_line" | grep -q "agent -p"; then
    break
  fi
  sleep 3
done

# 6. Capture output
tmux capture-pane -t cursor -p
```

**Why `-p` mode is better for automation:**
- No interactive TUI (cleaner output)
- Exits automatically when task completes
- Works with `--output-format text/json`
- No need to poll for progress percentage

**Alternative: Interactive mode (for complex tasks)**

For tasks requiring multiple interactions or live monitoring:

```bash
# Run in interactive mode
tmux send-keys -t cursor "agent 'Your task here'" Enter

# Wait with fixed timeout (less reliable)
sleep 60  # Adjust based on task complexity

# Capture output
tmux capture-pane -t cursor -p -S -100
```

**Why this works:**
- tmux provides a persistent pseudo-terminal (PTY)
- Cursor's TUI requires interactive terminal capabilities
- Direct `agent` calls from subprocess/exec hang without TTY

**What does NOT work:**
```bash
# ❌ These will hang indefinitely:
agent "task"                    # No TTY
agent -p "task"                 # No TTY  
subprocess.run(["agent", ...])  # No TTY
script -c "agent ..." /dev/null # May crash Cursor
```

### Helper Script: cursor-run.sh

For convenient automation, use this helper script:

```bash
#!/bin/bash
# cursor-run.sh - Run Cursor agent tasks with smart completion detection
# Usage: cursor-run.sh "agent -p 'your task' --output-format text"

TMUX_SESSION="${CURSOR_TMUX_SESSION:-cursor}"
WORKDIR="${CURSOR_WORKDIR:-$(pwd)}"
TIMEOUT="${CURSOR_TIMEOUT:-300}"  # 5 minutes default
POLL_INTERVAL=3

# Ensure tmux session exists
if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
  tmux new-session -d -s "$TMUX_SESSION"
  sleep 1
fi

# Send command
tmux send-keys -t "$TMUX_SESSION" "cd $WORKDIR && $1" Enter

# Wait for completion (detect shell prompt)
start_time=$(date +%s)
while true; do
  elapsed=$(( $(date +%s) - start_time ))
  [ $elapsed -ge $TIMEOUT ] && echo "ERROR: Timeout" >&2 && exit 1
  
  last_line=$(tmux capture-pane -t "$TMUX_SESSION" -p | grep -v '^$' | tail -1)
  if echo "$last_line" | grep -qE '(\$|%)\s*$' && ! echo "$last_line" | grep -q "agent -p"; then
    break
  fi
  sleep $POLL_INTERVAL
done

# Output result
tmux capture-pane -t "$TMUX_SESSION" -p | sed '/^$/d'
```

**Usage:**
```bash
chmod +x cursor-run.sh
./cursor-run.sh "agent -p 'Analyze this codebase' --output-format text"
```

## Rules & Configuration

The agent automatically loads rules from:
- `.cursor/rules`
- `AGENTS.md`
- `CLAUDE.md`

Use `/rules` command to create and edit rules directly from the CLI.

## MCP Integration

MCP servers are automatically loaded from `mcp.json` configuration.

Enable/disable servers on the fly:

```
/mcp enable server-name
/mcp disable server-name
```

**Note:** Server names with spaces are fully supported.

## Workflows

### Code Review

Perform a code review on the current changes or a specific branch:

```bash
agent -p 'Review the changes in the current branch against main. Focus on security and performance.'
```

### Refactoring

Refactor code for better readability or performance:

```bash
agent -p 'Refactor src/utils.ts to reduce complexity and improve type safety.'
```

### Debugging

Analyze logs or error messages to find the root cause:

```bash
agent -p 'Analyze the following error log and suggest a fix: [paste log here]'
```

### Git Integration

Automate git operations with context awareness:

```bash
agent -p 'Generate a commit message for the staged changes adhering to conventional commits.'
```

### Batch Processing (CI/CD)

Run automated checks in CI pipelines:

```bash
# Set API key in CI environment
export CURSOR_API_KEY=$CURSOR_API_KEY

# Run security audit with JSON output
agent -p 'Audit this codebase for security vulnerabilities' --output-format json --force

# Generate test coverage report
agent -p 'Run tests and generate coverage report' --output-format text
```

### Multi-file Analysis

Use context selection to analyze multiple files:

```bash
agent
# Then in interactive mode:
@src/api/
@src/models/
Review the API implementation for consistency with our data models
```
