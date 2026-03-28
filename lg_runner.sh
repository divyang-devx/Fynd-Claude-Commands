#!/bin/bash
set -eo pipefail

KEYWORD="$1"        # "uat" or "prod"
ACCOUNT_TYPE="$2"   # "development" or "live"
CONTEXT_FILE=".fdk/context.json"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  /fy runner  [keyword: $KEYWORD]"
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
    -re {https://[^\r\n]+} {
      set url \$expect_out(0,string)
      log_user 0
      puts \"\n🔗 Login URL (click to open):\n\033\]8;;\$url\033\\\\\$url\033\]8;;\033\\\\\n\"
      log_user 1
      exp_continue
    }
    \"Open link on browser\" {
      exp_continue
    }
    \"Timeout: Please run fdk login command again\" {
      puts \"\n✖ FDK login timed out. Please run /fy -lg or /fy -lgp again.\n\"
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
  # Path 1 — matching context found, set active_context
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
  # Path 2 — no match, run fdk theme context -n
  echo "  No context found matching \"$KEYWORD\". Running fdk theme context -n..."
  echo "  Auto-selecting account type: $ACCOUNT_TYPE"
  echo ""

  if [ "$ACCOUNT_TYPE" = "live" ]; then
    SELECT_KEYS="\x1b\[B\r"
  else
    SELECT_KEYS="\r"
  fi

  expect -c "
    set timeout -1
    log_user 1
    spawn fdk theme context -n
    expect {
      \"FDK-0004\" {
        puts \"\n✖ Context with the same name already exists.\n   Rename the existing context in .fdk/context.json to include 'uat' or 'prod',\n   then rerun /fy -lg or /fy -lgp.\n\"
        exit 1
      }
      \"403\" {
        puts \"\n✖ Not authorised. You may be logged into the wrong organisation.\n   Rerun /fy -lg or /fy -lgp to login with the correct account.\n\"
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

# ── Step 3: fdk theme serve ────────────────────────────────────────────────────

echo "▶ Step 3: fdk theme serve..."
echo ""

exec fdk theme serve
