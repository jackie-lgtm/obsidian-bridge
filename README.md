# obsidian-bridge

A Claude Code plugin that writes session notes into a specified Obsidian vault. Inbox-only write policy by default — the human triages into hub notes themselves.

## What it does

When you tell Claude "save this to Obsidian" (or similar), this skill:

1. Shows you a preview (filename + frontmatter + first 10 lines)
2. Waits for your explicit approval
3. Writes the note to your vault's `99 - Inbox/` folder
4. Never touches existing notes
5. Never reads other vaults on your machine

## Install

### Prerequisites

- Claude Code installed and working
- Obsidian installed, with at least one vault open at least once (so Obsidian's registry file exists)
- macOS (the vault resolver script is macOS-specific)

### Install steps

From Claude Code, add this plugin's marketplace:

```
/plugin marketplace add <path-or-url-to-this-repo>
```

Then install:

```
/plugin install obsidian-bridge
```

Restart Claude Code.

### First-run configuration

The first time you ask Claude to save something to Obsidian, it will prompt you for:
- Your vault name (e.g., `Bryan Brain`)
- The absolute path to your vault

Claude writes the config to `~/.claude/obsidian-bridge.config.json`. You can edit this file directly if your vault path changes.

Example config:

```json
{
  "vault_name": "Bryan Brain",
  "vault_path": "/Users/brian/Library/Mobile Documents/iCloud~md~obsidian/Documents/Bryan Synced Brain/Bryan Brain",
  "inbox_folder": "99 - Inbox",
  "write_policy": "inbox_only",
  "owner": "Brian"
}
```

### Verify vault detection

You can test the vault resolver script directly:

```bash
~/.claude/plugins/.../skills/obsidian-bridge/scripts/resolve-vault.sh "Bryan Brain"
```

It should print the absolute path to your vault. If it fails, check:
- Is Obsidian installed?
- Have you opened the vault in Obsidian at least once?
- Is the vault name spelled exactly as Obsidian shows it?

## Usage

Ask Claude to save a note:

```
> Save this conversation to Obsidian
> Log this decision to my brain
> Add this insight to my notes
```

Claude will:
1. Generate a filename: `YYYY-MM-DD-HHMM - {slug}.md`
2. Generate frontmatter with `type`, `tags`, `status: inbox`, etc.
3. Generate a structured body (Summary, Details, Related, Source)
4. Show you a preview
5. Wait for `yes` / `confirmed` before writing

## Triage workflow

After Claude writes a note, it lives in `{vault}/99 - Inbox/`. Open Obsidian:

1. Sort the Inbox folder by filename (newest/oldest first)
2. Read each note's `## Summary` section
3. Decide: keep, merge, or discard
4. For keepers: move to the appropriate folder, change `status: inbox` → `status: triaged`
5. Add `[[wiki-links]]` to relevant hub notes

See `skills/obsidian-bridge/reference/folder-structure.md` for a recommended vault layout.

## Safety guarantees

This skill will **never**:
- Modify existing notes in your vault
- Write outside the configured Inbox folder
- Read notes from other vaults on your machine
- Upload vault content to any remote service
- Bulk-import, bulk-delete, or reorganize notes

## Configuration reference

See the files in `skills/obsidian-bridge/reference/` for:
- `naming-conventions.md` — filename rules
- `frontmatter-schema.md` — YAML frontmatter spec
- `folder-structure.md` — recommended vault organization

## Versioning

This plugin follows semver. Current version: `0.1.0`.

## License

MIT
