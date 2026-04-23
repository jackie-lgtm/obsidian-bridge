#!/usr/bin/env bash
# build-entity-index.sh
#
# Rebuilds the obsidian-bridge entity index from two sources:
#   1. claude-mem observations (via sqlite)
#   2. Obsidian vault frontmatter (via file scan)
#
# Produces: ~/.claude/obsidian-bridge.entities.json
#
# Usage:
#   ./build-entity-index.sh [--vault PATH] [--profile] [--dry-run]
#
#   --vault PATH    Override the vault path from config
#   --profile       Also rebuild the "About Brian.md" profile note
#   --dry-run       Show what would be written, don't write
#
# Dependencies:
#   - python3 (macOS built-in)
#   - sqlite3 (macOS built-in)
#   - claude-mem plugin installed (for observation DB access)

set -euo pipefail

# ============================================================
# Parse args
# ============================================================
VAULT_PATH=""
REBUILD_PROFILE=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault) VAULT_PATH="$2"; shift 2 ;;
    --profile) REBUILD_PROFILE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

# ============================================================
# Load config
# ============================================================
CONFIG="$HOME/.claude/obsidian-bridge.config.json"
if [[ ! -f "$CONFIG" ]]; then
  echo "error: config not found at $CONFIG" >&2
  echo "Run obsidian-bridge first to create it." >&2
  exit 1
fi

if [[ -z "$VAULT_PATH" ]]; then
  VAULT_PATH=$(python3 -c "import json; print(json.load(open('$CONFIG'))['vault_path'])")
fi

if [[ ! -d "$VAULT_PATH" ]]; then
  echo "error: vault path does not exist: $VAULT_PATH" >&2
  exit 3
fi

INBOX_FOLDER=$(python3 -c "import json; print(json.load(open('$CONFIG')).get('inbox_folder', '99 - Inbox'))")
OWNER=$(python3 -c "import json; print(json.load(open('$CONFIG')).get('owner', 'User'))")

# ============================================================
# Locate claude-mem database
# ============================================================
# claude-mem stores its data under ~/.claude/plugins/data/claude-mem-thedotmack/
MEM_DB_CANDIDATES=(
  "$HOME/.claude/plugins/data/claude-mem-thedotmack/claude-mem.db"
  "$HOME/.claude/plugins/data/claude-mem-thedotmack/observations.db"
  "$HOME/.claude/plugins/data/claude-mem-thedotmack/mem.sqlite"
)

MEM_DB=""
for candidate in "${MEM_DB_CANDIDATES[@]}"; do
  if [[ -f "$candidate" ]]; then
    MEM_DB="$candidate"
    break
  fi
done

if [[ -z "$MEM_DB" ]]; then
  echo "warning: claude-mem database not found. Building entity index from vault only." >&2
  echo "         Expected one of: ${MEM_DB_CANDIDATES[*]}" >&2
fi

# ============================================================
# Build entity index (Python for convenience)
# ============================================================
INDEX_PATH="$HOME/.claude/obsidian-bridge.entities.json"
TMP_INDEX="${INDEX_PATH}.new"

python3 <<PYEOF
import json
import os
import re
import sqlite3
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path

vault = Path("$VAULT_PATH")
inbox = vault / "$INBOX_FOLDER"
mem_db = "$MEM_DB" if "$MEM_DB" else None
dry_run = $DRY_RUN == 1

entities = defaultdict(lambda: {
    "type": "unknown",
    "aliases": [],
    "memory_refs": [],
    "vault_notes": [],
    "last_seen": None,
    "mention_count": 0,
})

# ------------------------------------------------------------
# Scan vault frontmatter for entities
# ------------------------------------------------------------
# We only scan Inbox + skill-written notes (source: obsidian-bridge-auto or claude-session).
# We do NOT scan user-owned notes to respect their privacy within their own vault.

def extract_frontmatter(text):
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    if end == -1:
        return None
    fm_text = text[3:end].strip()
    fm = {}
    for line in fm_text.split("\n"):
        if ":" in line:
            k, v = line.split(":", 1)
            fm[k.strip()] = v.strip()
    return fm

def extract_wikilinks(text):
    return re.findall(r"\[\[([^\]|]+)(?:\|[^\]]+)?\]\]", text)

note_count = 0
for md_file in vault.rglob("*.md"):
    try:
        text = md_file.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        continue
    fm = extract_frontmatter(text)
    if not fm:
        continue
    # Only index skill-written notes
    source = fm.get("source", "")
    if source not in ("claude-session", "obsidian-bridge-auto"):
        continue

    note_count += 1
    rel_path = str(md_file.relative_to(vault))
    mem_ref = fm.get("memory-ref", "")
    created = fm.get("created", "")

    # Pull wiki-linked entities from frontmatter + body
    entity_field = fm.get("entities", "")
    for link in extract_wikilinks(entity_field + "\n" + text):
        link = link.strip()
        if not link or len(link) > 100:
            continue
        e = entities[link]
        e["vault_notes"].append(rel_path)
        if mem_ref and mem_ref not in e["memory_refs"]:
            e["memory_refs"].append(mem_ref)
        if created and (not e["last_seen"] or created > e["last_seen"]):
            e["last_seen"] = created
        e["mention_count"] += 1

# ------------------------------------------------------------
# Scan claude-mem observations for entities
# ------------------------------------------------------------
# Best-effort: inspect DB schema, extract text fields, find proper nouns.
# If the DB schema doesn't match expectations, skip gracefully.

if mem_db:
    try:
        conn = sqlite3.connect(f"file:{mem_db}?mode=ro", uri=True)
        cur = conn.cursor()
        # Find tables
        cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = [row[0] for row in cur.fetchall()]
        # Common table names for observation stores
        obs_table = None
        for candidate in ("observations", "memory", "observation", "notes"):
            if candidate in tables:
                obs_table = candidate
                break
        if obs_table:
            cur.execute(f"PRAGMA table_info({obs_table})")
            cols = [row[1] for row in cur.fetchall()]
            # Best-effort text column
            text_col = next((c for c in ("content", "text", "body", "observation", "summary") if c in cols), None)
            id_col = next((c for c in ("id", "observation_id", "uuid") if c in cols), "rowid")
            date_col = next((c for c in ("created_at", "timestamp", "date") if c in cols), None)
            if text_col:
                select_cols = f"{id_col}, {text_col}" + (f", {date_col}" if date_col else "")
                cur.execute(f"SELECT {select_cols} FROM {obs_table} LIMIT 5000")
                for row in cur.fetchall():
                    obs_id = row[0]
                    content = row[1] or ""
                    obs_date = row[2] if date_col and len(row) > 2 else ""
                    # Extract wiki-links from observation body (if present)
                    for link in extract_wikilinks(content):
                        link = link.strip()
                        if not link or len(link) > 100:
                            continue
                        e = entities[link]
                        ref = f"mem_{obs_id}"
                        if ref not in e["memory_refs"]:
                            e["memory_refs"].append(ref)
                        if obs_date and (not e["last_seen"] or str(obs_date) > str(e["last_seen"])):
                            e["last_seen"] = str(obs_date)
                        e["mention_count"] += 1
        conn.close()
    except Exception as ex:
        print(f"warning: could not read claude-mem DB: {ex}", file=sys.stderr)

# ------------------------------------------------------------
# Post-process: dedupe, infer types, sort
# ------------------------------------------------------------
for name, data in entities.items():
    data["vault_notes"] = sorted(set(data["vault_notes"]))
    data["memory_refs"] = sorted(set(data["memory_refs"]))
    # Simple heuristic for type
    if any("person" in n.lower() or "People" in n for n in data["vault_notes"]):
        data["type"] = "person"
    elif any("Project" in n for n in data["vault_notes"]):
        data["type"] = "project"
    elif data["mention_count"] >= 5:
        data["type"] = "concept"

sorted_entities = dict(sorted(
    entities.items(),
    key=lambda kv: kv[1]["mention_count"],
    reverse=True,
))

output = {
    "version": 1,
    "rebuilt_at": datetime.now().isoformat(timespec="minutes"),
    "owner": "$OWNER",
    "vault_path": "$VAULT_PATH",
    "source_stats": {
        "vault_notes_scanned": note_count,
        "mem_db": mem_db or "not found",
        "total_entities": len(sorted_entities),
    },
    "entities": sorted_entities,
}

if dry_run:
    print(json.dumps(output, indent=2))
    print(f"\n[dry-run] would write {len(sorted_entities)} entities to {os.path.expanduser('~/.claude/obsidian-bridge.entities.json')}", file=sys.stderr)
else:
    tmp = os.path.expanduser("~/.claude/obsidian-bridge.entities.json.new")
    final = os.path.expanduser("~/.claude/obsidian-bridge.entities.json")
    with open(tmp, "w") as f:
        json.dump(output, f, indent=2)
    os.replace(tmp, final)
    print(f"wrote {len(sorted_entities)} entities to {final}", file=sys.stderr)
    print(f"scanned {note_count} vault notes", file=sys.stderr)
PYEOF

# ============================================================
# Rebuild profile note (optional)
# ============================================================
if [[ $REBUILD_PROFILE -eq 1 ]]; then
  echo "" >&2
  echo "Profile note rebuild is performed by Claude interactively, not by this script." >&2
  echo "Ask Claude: \"Rebuild my About Brian profile note.\"" >&2
fi

echo "done." >&2
