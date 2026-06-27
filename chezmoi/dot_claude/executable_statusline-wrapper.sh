#!/usr/bin/env bash
# Wrapper around @owloops/claude-powerline that appends a live MCP status
# segment. Green when all configured MCP servers are Connected; red otherwise.
#
# `claude mcp list` runs live health probes and is slow, so results are cached
# in a tmp file and refreshed in the background.

set -u

CACHE="${TMPDIR:-/tmp}/claude-mcp-status.cache"
TTL=30

INPUT=$(cat)

POWERLINE=$(printf '%s' "$INPUT" \
  | npx -y @owloops/claude-powerline@latest --style=powerline 2>/dev/null \
  | head -n1)

now=$(date +%s)
mtime=0
if [ -f "$CACHE" ]; then
  # Homebrew coreutils puts GNU stat first on PATH (where -f is filesystem info,
  # not format). Use BSD stat explicitly to read mtime on macOS.
  mtime=$(/usr/bin/stat -f %m "$CACHE" 2>/dev/null)
  [ -z "$mtime" ] && mtime=0
fi
if [ ! -f "$CACHE" ] || [ $(( now - mtime )) -gt "$TTL" ]; then
  ( claude mcp list >"$CACHE.tmp" 2>/dev/null && mv "$CACHE.tmp" "$CACHE" ) \
    </dev/null >/dev/null 2>&1 &
  disown 2>/dev/null || true
fi

MCP_SEG=""
if [ -f "$CACHE" ]; then
  TOTAL=$(grep -cE ' - (✓|!|✗)' "$CACHE" 2>/dev/null)
  READY=$(grep -cE ' - ✓ Connected' "$CACHE" 2>/dev/null)
  : "${TOTAL:=0}"
  : "${READY:=0}"
  if [ "$TOTAL" -gt 0 ]; then
    if [ "$READY" -eq "$TOTAL" ]; then
      COLOR=$'\033[32m'
    else
      COLOR=$'\033[31m'
    fi
    RESET=$'\033[0m'
    MCP_SEG=" ${COLOR}${READY}/${TOTAL} MCP${RESET}"
  fi
else
  MCP_SEG=$' \033[90m…/… MCP\033[0m'
fi

printf '%s%s\n' "$POWERLINE" "$MCP_SEG"
