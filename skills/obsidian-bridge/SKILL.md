---
name: obsidian-bridge
description: Write Claude Code session notes into the user's Obsidian vault. Use when the user says "save to Obsidian", "add to my notes", "log this to my brain", "put this in my vault", or similar intent to persist the current conversation or a specific insight into Obsidian. Writes only to the configured vault's Inbox folder by default — the user triages into hub notes themselves.
---

# Obsidian Bridge

This skill writes markdown notes from Claude Code sessions into an Obsidian vault. It follows a **strict Inbox-only write policy** by default — Claude never modifies existing notes, never writes outside the configured Inbox folder, and never reads other vaults on the machine.

## When to use

Trigger this skill when the user expresses intent to persist session content to Obsidian:
- "Save this to Obsidian"
- "Add to my notes"
- "Log this to my brain"
- "Put this in my vault"
- "Capture this for later"

Do **not** auto-trigger. The user must explicitly ask.

## Configuration

The skill reads its configuration from `~/.claude/obsidian-bridge.config.json`. If the file does not exist on first run, Claude MUST prompt the user to create it (see "First-run setup" below). The file has this shape:

```json
{
  "vault_name": "Bryan Brain",
  "vault_path": "/Users/brian/Library/Mobile Documents/iCloud~md~obsidian/Documents/Bryan Synced Brain/Bryan Brain",
  "inbox_folder": "99 - Inbox",
  "write_policy": "inbox_only",
  "owner": "Brian"
}
```

- `vault_path` — absolute path to the Obsidian vault root on this machine
- `inbox_folder` — relative path inside the vault where all new notes go
- `write_policy` — must be `"inbox_only"` unless the user has explicitly granted broader permission
- `owner` — human name, used for frontmatter and audit trail

## First-run setup

If `~/.claude/obsidian-bridge.config.json` does not exist:

1. Tell the user: "Obsidian bridge is not configured yet. I need to know where your vault is."
2. Ask for: vault name, vault path on this machine
3. Verify the vault path exists and contains an `.obsidian/` folder (that's how we confirm it's a real vault)
4. Verify (or create, with permission) the Inbox folder inside the vault
5. Write the config file with the resolved values
6. Confirm setup complete, then proceed with the user's original request

## Writing a note

### Filename pattern
```
YYYY-MM-DD-HHMM - {kebab-case-slug}.md
```
Example: `2026-04-22-1730 - sisai-interview-debrief.md`

The slug is derived from the note's topic. Keep it short (3–6 words), lowercase, hyphen-separated. Never use the user's private names in filenames unless the user explicitly names them.

### Required frontmatter

```yaml
---
type: session | insight | decision | task | reference | person | project
source: claude-session
created: YYYY-MM-DDTHH:MM
owner: {config.owner}
session-topic: {short description}
tags: [tag1, tag2]
status: inbox
---
```

- `status: inbox` — tells the user this note has not been triaged yet
- `tags` — start with 2–4 tags. Prefer tags that already exist in the vault if Claude has observed them in this session.

### Body structure

Every note body follows this template:

```markdown
# {Title}

## Summary
{2-4 sentence summary of what this note captures}

## Details
{The actual content — conversation excerpts, decisions, insights, data}

## Related
- {[[wiki-link]] to any existing hub notes the user mentioned in this session}

## Source
- Session: {date and brief topic}
- Captured by: Claude Code via obsidian-bridge v0.1.0
```

The `Related` section uses `[[wiki-link]]` format. Only link to notes the user has explicitly referenced in the session — never guess at note names.

## Write policy (strict)

1. **Only write into** `{vault_path}/{inbox_folder}/`
2. **Never modify** an existing file in the vault — if a filename collision happens, append `-2`, `-3`, etc.
3. **Never read** files outside `{vault_path}/{inbox_folder}/` unless the user explicitly asks Claude to reference an existing note
4. **Never read** other Obsidian vaults on the machine, even if visible
5. **Never send** vault content outside the local machine without explicit user confirmation for that specific transmission

## Integration with claude-mem (optional)

If the `claude-mem` plugin is installed (detectable via the presence of `mcp__plugin_claude-mem_mcp-search__*` tools), the skill can enrich notes with:
- A link to the originating claude-mem session ID in frontmatter (`session-id: {id}`)
- Cross-references to related past observations via `mcp__plugin_claude-mem_mcp-search__search`

If claude-mem is **not** installed, the skill works standalone using only the current session's context. Do not treat claude-mem as a dependency.

## Confirmation workflow

Before writing any note:
1. Show the user a preview: filename, frontmatter, and first 10 lines of body
2. Ask: "Write this to `{inbox_folder}`?"
3. Wait for explicit approval (`yes`, `confirmed`, `write it`)
4. Only then use the Write tool

Never skip the preview step, even for short notes.

## Reference files

See `reference/` folder for:
- `naming-conventions.md` — detailed filename rules
- `frontmatter-schema.md` — complete frontmatter spec
- `folder-structure.md` — recommended vault folder organization for triage

## What this skill will NOT do

- Will not modify existing notes in the vault
- Will not write outside the Inbox folder
- Will not read other vaults on the machine
- Will not push vault content to any remote service
- Will not bulk-import, bulk-delete, or reorganize existing notes
- Will not make assumptions about vault structure beyond what's in the config file
