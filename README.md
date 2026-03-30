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
| `/fy -sy` | FDK login + theme sync → theme serve (UAT) |
| `/fy -syp` | FDK login + theme sync → theme serve (PROD) |
| `/fy --help` | Show available commands |

## How it works

### Serve (`-lg` / `-lgp`)
1. `fdk login` — authenticates with your org
2. Auto-sets the theme context (matches `uat` or `prod` in context name)
3. Runs `fdk theme serve` (fully interactive)

### Sync (`-sy` / `-syp`)
1. `fdk login` — authenticates with your org
2. Auto-sets the theme context (matches `uat` or `prod` in context name)
3. Prompts confirmation (Yes/No with arrow keys) showing target context + domain
4. Runs `fdk theme sync` (fully interactive) — pipeline breaks on failure
5. On successful sync, automatically runs `fdk theme serve` (fully interactive)

> Any failure in sync or serve breaks the pipeline immediately with a non-zero exit code.
