# Recommended Vault Folder Structure

The skill writes to a specific set of folders. Brian's vault can have any structure he wants outside those folders — the skill never touches user-owned folders.

## Folders the skill uses

| Folder | Purpose | Who writes here |
|---|---|---|
| `99 - Inbox/` | All new atomic notes land here for triage | Skill (every save) |
| `00 - Clusters/` | Auto-generated thought groupings | Skill (weekly rebuild) |
| `00 - Clusters/.archive/` | Previous cluster versions | Skill (on rebuild) |
| `About Brian.md` (root) | Profile note | Skill (weekly rebuild) |

Everything else is Brian's.

## Recommended full layout (Brian decides his own)

```
Bryan Brain/
├── About Brian.md                      ← skill-managed, profile
├── 00 - Clusters/                      ← skill-managed, auto-groupings
│   ├── Cluster - Customer Retention.md
│   ├── Cluster - Project Alpha.md
│   └── .archive/                       ← old cluster versions
├── 10 - Projects/                      ← Brian's (skill reads on request only)
│   ├── Project Alpha.md                ← hub note for Project Alpha
│   └── Project Beta.md
├── 20 - People/                        ← Brian's
│   ├── Sarah.md
│   └── Marcus.md
├── 30 - Knowledge/                     ← Brian's
│   ├── authentication-patterns.md
│   └── churn-metrics.md
├── 40 - Decisions/                     ← Brian's
│   └── 2026-04-18 - auth-decision.md
├── 50 - Meetings/                      ← Brian's
├── 90 - Sessions/                      ← Brian moves triaged session notes here
├── 99 - Inbox/                         ← skill-managed, new notes land here
│   └── 2026-04-22-1545 - t7a2 - ...md
└── Attachments/                        ← Brian's (images, PDFs)
```

## Numeric prefixes

- `00-09` = meta / auto-generated (skill manages)
- `10-89` = organized content (Brian manages)
- `90-99` = triage / intake (skill writes to 99, Brian moves to 90+)

Gaps (`10`, `20`, `30`) let Brian insert new categories without renumbering.

## Triage workflow

When Brian opens `99 - Inbox/`:

1. **Sort by filename** (timestamp prefix = chronological)
2. **Group by thread ID** (Obsidian's search: `t7a2`)
3. **Read each note's body** (max 120 words — fast to scan)
4. **For each thread, decide:**
   - **Keep all** → move all thread notes to the right folder, change `status: inbox → triaged`
   - **Keep some** → move the good ones, delete the rest
   - **Merge** → copy content into an existing hub note, delete the inbox notes
   - **Discard** → delete
5. **Update the hub note** (if one exists) with a `[[link]]` to the kept note(s)

## Hub notes (Brian's spine)

Hub notes in `10 - Projects/`, `20 - People/`, etc. are Brian's manually-maintained index pages. The skill never writes to them directly, but:
- When writing new atomic notes, the skill checks if a hub note exists for a mentioned entity
- If yes, it adds `[[Hub Note Name]]` to the new note's `entities` frontmatter
- Brian sees the new note appear in Obsidian's backlinks pane for that hub

This way, hub notes auto-populate backlinks without the skill mutating them.

## The `.archive/` pattern

When the skill overwrites a cluster note (weekly rebuild), it first moves the old version to `00 - Clusters/.archive/` with the date appended:
```
00 - Clusters/.archive/Cluster - Customer Retention - 2026-04-15.md
```

Brian can diff to see how his thinking evolved.

## What Brian should NEVER put in skill-managed folders

- Don't put hand-written notes in `99 - Inbox/` — they'll get triaged like auto-notes
- Don't put hand-written notes in `00 - Clusters/` — they'll be overwritten
- Don't edit `About Brian.md` fields that start with `source: obsidian-bridge-auto` without changing `source:` to `manual` first

## Obsidian UI tips for Brian

- **Tag pane**: shows nested tags like `domain/product` → clusters by domain visually
- **Graph view**: filter by `tag:#thought-type/decision` to see his decision graph
- **Backlinks pane**: on any hub note, shows every atomic note that mentions it
- **Search**: `thread:t7a2` finds all notes from a single voice stream
