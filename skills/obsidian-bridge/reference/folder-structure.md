# Recommended Vault Folder Structure

This is the folder structure the skill is designed to work with. **Brian's vault does not need to match this exactly** — the only folder the skill actively writes to is `{inbox_folder}` from the config (default: `99 - Inbox`).

This doc is a reference for Brian when he triages notes out of the Inbox.

## Recommended layout

```
Bryan Brain/
├── 00 - Hubs/              # Top-level index/hub notes (one per business, project, etc.)
├── 10 - Projects/          # Active project notes
├── 20 - People/            # Notes about people, clients, partners
├── 30 - Knowledge/         # Reusable knowledge, how-tos, references
├── 40 - Decisions/         # Decision log
├── 50 - Meetings/          # Meeting notes
├── 90 - Sessions/          # Claude session digests (after triage from Inbox)
├── 99 - Inbox/             # ← obsidian-bridge writes here, Brian triages from here
└── Attachments/            # Images, PDFs, files
```

## Numeric prefixes

Prefixes (`00`, `10`, `20`, etc.) keep folders sortable in Obsidian's file explorer. Use gaps (`10`, `20`, not `01`, `02`) so you can insert new categories without renumbering everything.

## Inbox triage workflow

When Brian opens Obsidian and sees notes in `99 - Inbox/`:

1. **Open the oldest note** (sorted by filename timestamp)
2. **Read the summary** in the `## Summary` section
3. **Decide**: Keep? Merge into existing note? Discard?
4. **If keep**: move to the appropriate folder, change `status: inbox` → `status: triaged` in frontmatter
5. **If merge**: copy content into existing hub note, delete the inbox note
6. **If discard**: delete the file

Tip: Use Obsidian's search to find the correct hub note by tag.

## Hub notes

Hub notes in `00 - Hubs/` are the "spine" of the vault. Each one is an index for a major area of Brian's life or work. Example:

```markdown
---
type: hub
status: active
tags: [hub]
---

# AJ Projects

## Active Projects
- [[Project Alpha]]
- [[Project Beta]]

## Clients
- [[Client X]]
- [[Client Y]]

## Recent Sessions
- [[2026-04-22-1730 - api-rate-limit-decision]]
```

When Brian triages a note out of Inbox, he adds a `[[wiki-link]]` to it from the relevant hub note. This is how the vault's graph grows over time.
