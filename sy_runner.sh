#!/bin/bash
set -eo pipefail

KEYWORD="$1"        # "uat" or "prod"
ACCOUNT_TYPE="$2"   # "development" or "live"
CONTEXT_FILE=".fdk/context.json"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  /fy sync runner  [keyword: $KEYWORD]"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Step 1: fdk login ──────────────────────────────────────────────────────────

echo "▶ Step 1: fdk login..."
echo ""

TMPFILE=$(mktemp)

expect -c "
  set timeout -1
  log_user 1
  spawn fdk login
  expect {
    \"Do you wish to change the organization?\" {
      send \"\r\"
      exp_continue
    }
    \"Open link on browser\" {
      puts \"\n⏳ Waiting for organization selection in browser... (complete login in the opened tab)\n\"
      exp_continue
    }
    \"Timeout: Please run fdk login command again\" {
      puts \"\n✖ FDK login timed out. Please run /fy -sy or /fy -syp again.\n\"
      exit 1
    }
    \"Logged in successfully in organization\" {
      exp_continue
    }
    eof
  }
" 2>&1 | tee "$TMPFILE"

echo ""

if ! grep -q "Logged in successfully in organization" "$TMPFILE"; then
  rm -f "$TMPFILE"
  echo "✖ Login failed. Stopping."
  exit 1
fi

ORG_NAME=$(grep "Logged in successfully in organization" "$TMPFILE" | sed 's/.*organization //')
rm -f "$TMPFILE"

echo "✔ Logged in as: $ORG_NAME"
echo ""

# ── Step 2: set theme context ──────────────────────────────────────────────────

echo "▶ Step 2: resolving theme context..."
echo ""

TARGET_CONTEXT=""

if [ -f "$CONTEXT_FILE" ]; then
  TARGET_CONTEXT=$(jq -r --arg kw "$KEYWORD" \
    '.theme.contexts | keys[] | select(ascii_downcase | contains($kw))' \
    "$CONTEXT_FILE" | head -1)
fi

if [ -n "$TARGET_CONTEXT" ]; then
  CURRENT=$(jq -r '.theme.active_context' "$CONTEXT_FILE")
  if [ "$CURRENT" = "$TARGET_CONTEXT" ]; then
    echo "✔ Context already active: $TARGET_CONTEXT (no change)"
  else
    echo "  Switching context: $CURRENT → $TARGET_CONTEXT"
    jq --arg ctx "$TARGET_CONTEXT" '.theme.active_context = $ctx' "$CONTEXT_FILE" > "$CONTEXT_FILE.tmp" && mv "$CONTEXT_FILE.tmp" "$CONTEXT_FILE"
    echo "✔ Context set to: $TARGET_CONTEXT"
  fi
  echo ""
else
  if [ "$ACCOUNT_TYPE" = "live" ]; then
    SELECT_KEYS="\x1b\[B\r"
  else
    SELECT_KEYS="\r"
  fi

  echo "  No context found matching \"$KEYWORD\". Running fdk theme context -n..."
  echo "  Auto-selecting account type: $ACCOUNT_TYPE"
  echo ""

  expect -c "
    set timeout -1
    log_user 1
    spawn fdk theme context -n
    expect {
      \"FDK-0004\" {
        puts \"\n✖ Context with the same name already exists.\n   Rename the existing context in .fdk/context.json to include 'uat' or 'prod',\n   then rerun /fy -sy or /fy -syp.\n\"
        exit 1
      }
      \"403\" {
        puts \"\n✖ Not authorised. You may be logged into the wrong organisation.\n   Rerun /fy -sy or /fy -syp to login with the correct account.\n\"
        exit 1
      }
      \"Select accounts type\" {
        send \"$SELECT_KEYS\"
        puts \"\n⏳ Waiting for manual entries... (select company → sales channel → theme)\n\"
        interact
        catch wait result
        exit [lindex \$result 3]
      }
    }
  " || { echo "✖ Context setup failed. Stopping."; exit 1; }

  echo ""
  echo "✔ Context setup complete."
  echo "💡 Suggestion: Rename the new context in .fdk/context.json to include"
  echo "   \"uat\" or \"prod\" so future /fy runs auto-select it."
  echo ""
fi

# ── Step 3: fdk theme sync ─────────────────────────────────────────────────────

echo "▶ Step 3: fdk theme sync..."
echo ""

# Read active context name and domain for confirmation
ACTIVE_CONTEXT=$(jq -r '.theme.active_context' "$CONTEXT_FILE")
DOMAIN=$(jq -r --arg ctx "$ACTIVE_CONTEXT" '.theme.contexts[$ctx].domain // "unknown domain"' "$CONTEXT_FILE")

expect -c "
  set timeout -1
  log_user 1

  puts \"  You are syncing to: $ACTIVE_CONTEXT ($DOMAIN)\"
  puts \"  Do you want to proceed?\n\"

  proc show_menu {selected} {
    if {\$selected == 0} {
      puts -nonewline \"\r  > Yes   No  \"
    } else {
      puts -nonewline \"\r    Yes  > No  \"
    }
    flush stdout
  }

  show_menu 0
  set selected 0

  stty raw -echo
  while {1} {
    set ch [read stdin 1]
    if {\$ch == \"\r\" || \$ch == \"\n\"} {
      break
    }
    set seq \"\"
    if {\$ch == \"\x1b\"} {
      set seq [read stdin 2]
    }
    if {\$seq == \"\[D\" || \$seq == \"\[A\"} {
      set selected 0
      show_menu 0
    } elseif {\$seq == \"\[C\" || \$seq == \"\[B\"} {
      set selected 1
      show_menu 1
    }
  }
  stty -raw echo
  puts \"\"

  if {\$selected == 1} {
    puts \"\n  Sync cancelled.\n\"
    exit 0
  }

  puts \"\n⏳ Starting fdk theme sync...\n\"
  spawn fdk theme sync
  interact
  catch wait sync_result
  set sync_exit [lindex \$sync_result 3]

  if {\$sync_exit != 0} {
    puts \"\n✖ fdk theme sync failed (exit \$sync_exit). Stopping.\n\"
    exit \$sync_exit
  }

  puts \"\n✔ Sync complete.\n\"
  puts \"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\"
  puts \"▶ Step 4: fdk theme serve...\"
  puts \"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\"
  spawn fdk theme serve
  interact
  catch wait serve_result
  exit [lindex \$serve_result 3]
" || exit 1
