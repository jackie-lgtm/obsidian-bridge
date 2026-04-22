#!/usr/bin/env bash
# resolve-vault.sh
# Helper for obsidian-bridge: find an Obsidian vault on the current machine by name.
#
# Usage:
#   ./resolve-vault.sh "Bryan Brain"
#
# Reads Obsidian's local registry at:
#   ~/Library/Application Support/obsidian/obsidian.json
#
# Prints the absolute path of the matching vault to stdout, or exits 1 if not found.

set -euo pipefail

VAULT_NAME="${1:-}"

if [[ -z "$VAULT_NAME" ]]; then
  echo "error: vault name required" >&2
  echo "usage: $0 <vault-name>" >&2
  exit 2
fi

REGISTRY="$HOME/Library/Application Support/obsidian/obsidian.json"

if [[ ! -f "$REGISTRY" ]]; then
  echo "error: Obsidian registry not found at $REGISTRY" >&2
  echo "Is Obsidian installed on this machine?" >&2
  exit 3
fi

# Parse the JSON registry and find a vault whose path ends with the given name.
# Uses python3 (macOS ships with it) to avoid requiring jq.
VAULT_PATH=$(python3 -c "
import json, sys, os
name = sys.argv[1]
with open(sys.argv[2]) as f:
    data = json.load(f)
for vault_id, info in data.get('vaults', {}).items():
    path = info.get('path', '')
    if os.path.basename(path) == name:
        print(path)
        sys.exit(0)
sys.exit(1)
" "$VAULT_NAME" "$REGISTRY")

if [[ -z "$VAULT_PATH" ]]; then
  echo "error: no vault named '$VAULT_NAME' found in Obsidian registry" >&2
  exit 1
fi

# Verify the path exists and is actually a vault (has .obsidian/ subfolder)
if [[ ! -d "$VAULT_PATH" ]]; then
  echo "error: vault path does not exist: $VAULT_PATH" >&2
  exit 4
fi

if [[ ! -d "$VAULT_PATH/.obsidian" ]]; then
  echo "error: path exists but is not a valid Obsidian vault (no .obsidian/ folder): $VAULT_PATH" >&2
  exit 5
fi

echo "$VAULT_PATH"
