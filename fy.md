General-purpose project command dispatcher.

## Supported sub-commands
- `-lg`  → FDK login + theme serve (UAT context)
- `-lgp` → FDK login + theme serve (PROD context)
- `-sy`  → FDK login + theme sync  (UAT context)
- `-syp` → FDK login + theme sync  (PROD context)

---

## Steps to follow exactly:

### 1. Parse arguments
Check `$ARGUMENTS` — match the MOST specific flag first:
- If contains `--help` or `-h` → print help and stop:
  ```
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /fy — FDK project command dispatcher
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    SERVE COMMANDS  (fdk login → set context → fdk theme serve)
    ─────────────────────────────────────────────────────────
    /fy -lg    Start theme serve for UAT (development) context.
               Auto-matches context with "uat" in the name.
               Runs fdk theme context -n if no match found.

    /fy -lgp   Start theme serve for PROD (live) context.
               Auto-matches context with "prod" in the name.
               Runs fdk theme context -n if no match found.

    SYNC COMMANDS   (fdk login → set context → fdk theme sync)
    ─────────────────────────────────────────────────────────
    /fy -sy    Sync theme for UAT (development) context.
               Prompts confirmation before syncing.
               Full interactivity for sync questions.

    /fy -syp   Sync theme for PROD (live) context.
               Prompts confirmation before syncing.
               Full interactivity for sync questions.

    OTHER
    ─────────────────────────────────────────────────────────
    /fy --help   Show this help message.
    /fy -h       Alias for --help.

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ```
- If contains `-lgp` → `SUBCOMMAND = "lg"`,  `KEYWORD = "prod"`, `ACCOUNT_TYPE = "live"`
- If contains `-lg`  → `SUBCOMMAND = "lg"`,  `KEYWORD = "uat"`,  `ACCOUNT_TYPE = "development"`
- If contains `-syp` → `SUBCOMMAND = "sy"`,  `KEYWORD = "prod"`, `ACCOUNT_TYPE = "live"`
- If contains `-sy`  → `SUBCOMMAND = "sy"`,  `KEYWORD = "uat"`,  `ACCOUNT_TYPE = "development"`
- Otherwise → print and stop:
  ```
  Unknown sub-command. Run /fy --help to see available commands.
  ```

---

## SUBCOMMAND: lg

### 2. Open Terminal.app with lg runner

Get the absolute project path (directory containing the `.claude` folder).

Run this Bash command:
```bash
osascript -e "tell application \"Terminal\"
  activate
  do script \"cd 'PROJECT_PATH' && bash .claude/commands/lg_runner.sh 'KEYWORD' 'ACCOUNT_TYPE'\"
end tell"
```

Replace `PROJECT_PATH`, `KEYWORD`, and `ACCOUNT_TYPE` with actual values.

### 3. Print summary in Claude Code terminal

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /fy -lg or -lgp summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Keyword       : <KEYWORD>
  Account type  : <ACCOUNT_TYPE>
  Terminal      : Opened — Step 1: fdk login → Step 2: context → Step 3: serve
  Path          : <PROJECT_PATH>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## SUBCOMMAND: sy

### 2. Open Terminal.app with sy runner

Get the absolute project path (directory containing the `.claude` folder).

Run this Bash command:
```bash
osascript -e "tell application \"Terminal\"
  activate
  do script \"cd 'PROJECT_PATH' && bash .claude/commands/sy_runner.sh 'KEYWORD' 'ACCOUNT_TYPE'\"
end tell"
```

Replace `PROJECT_PATH`, `KEYWORD`, and `ACCOUNT_TYPE` with actual values.

### 3. Print summary in Claude Code terminal

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /fy -sy or -syp summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Keyword       : <KEYWORD>
  Account type  : <ACCOUNT_TYPE>
  Terminal      : Opened — Step 1: fdk login → Step 2: context → Step 3: sync
  Path          : <PROJECT_PATH>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
