# Fynd Claude Commands

Global Claude Code commands for FDK theme development.

## Install

```bash
git clone https://github.com/divyang-devx/Fynd-Claude-Commands.git ~/.claude/commands
chmod +x ~/.claude/commands/*.sh
```

## Update

```bash
cd ~/.claude/commands && git pull
```

## Prerequisites

```bash
brew install expect jq
```

> Also requires `fdk` CLI to be installed.

## Commands

| Command | Description |
|---|---|
| `/fy -lg` | FDK login + theme serve (UAT) |
| `/fy -lgp` | FDK login + theme serve (PROD) |
| `/fy -sy` | FDK login + theme sync (UAT) |
| `/fy -syp` | FDK login + theme sync (PROD) |
| `/fy --help` | Show available commands |

## How it works

Each `/fy` run:
1. `fdk login` — authenticates with your org
2. Auto-sets the theme context (matches `uat` or `prod` in context name)
3. Runs `fdk theme serve` or `fdk theme sync`
