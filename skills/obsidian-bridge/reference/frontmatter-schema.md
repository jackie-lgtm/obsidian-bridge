# Frontmatter Schema

All notes written by obsidian-bridge MUST have YAML frontmatter at the top of the file.

## Required fields (every note)

```yaml
---
type: session | insight | decision | task | reference | person | project | thread-part | cluster | profile
source: claude-session | obsidian-bridge-auto | manual
created: 2026-04-22T15:45
owner: Brian
memory-ref: mem_<observation-id>
status: inbox | triaged | archived
tags: [domain/X, topic/Y]
---
```

### Field definitions

| Field | Type | Description |
|---|---|---|
| `type` | enum | Primary classification. Drives folder placement during triage. |
| `source` | enum | Who/what wrote this note. **Safety-critical** — skill never overwrites `source: manual`. |
| `created` | ISO 8601 | Datetime written, local TZ. No seconds. |
| `owner` | string | Human owner (from config). |
| `memory-ref` | string | claude-mem observation ID. **REQUIRED** for bidirectional link. Format: `mem_<alphanumeric>`. |
| `status` | enum | Triage state. New notes are `inbox`. Brian changes to `triaged` after review. |
| `tags` | list | Layered taxonomy. See "Tag taxonomy" below. |

## Fields required for thread-part notes

When `type: thread-part` (atomic notes from a voice stream):

```yaml
thread: t7a2-<full-uuid>       # shared across all notes in the thread
thread-position: 2/3            # N-of-M position in the thread
entities: [[Project Alpha]], [[Sarah]]  # wiki-linked entities mentioned
```

## Fields required for cluster notes

When `type: cluster`:

```yaml
cluster-key: customer-retention      # stable slug for this cluster
updated: 2026-04-22                   # weekly rebuild timestamp
source-observations: 23               # count of claude-mem observations in this cluster
previous-version: 00 - Clusters/.archive/Cluster - Customer Retention - 2026-04-15.md
```

## Fields required for profile note

When `type: profile` (only for `About Brian.md`):

```yaml
confidence: high | medium | low
updated: 2026-04-22
source-observations: 47
```

## Optional fields

| Field | Use when |
|---|---|
| `session-id` | Linking to a specific claude-mem session |
| `related-notes: [[A]], [[B]]` | Brian explicitly referenced these notes |
| `decision: accepted \| rejected \| deferred` | For `type: decision` |
| `project` | If clearly scoped to one project |
| `priority: low \| medium \| high \| urgent` | User-set priority |
| `person` | For `type: person` — the person's canonical name |

## Tag taxonomy (layered)

Tags use `/` to create hierarchical namespaces. Obsidian shows these as nested in the tag pane — **this is how Brian sees groupings in the Obsidian UI**.

### Layer 1: Domain (always present)
- `domain/engineering`
- `domain/product`
- `domain/biz-ops`
- `domain/personal`
- `domain/research`

### Layer 2: Topic (0-2 per note)
- `topic/authentication`
- `topic/churn`
- `topic/onboarding`
- `topic/hiring`

### Layer 3: Thought type (optional)
- `thought-type/decision`
- `thought-type/hypothesis`
- `thought-type/observation`
- `thought-type/question`
- `thought-type/commitment`

### Layer 4: Status / quality (optional)
- `state/open` — unresolved thread
- `state/resolved` — closed out
- `state/blocked` — waiting on something

### Tag rules

- Minimum 2 tags (at least one `domain/X`)
- Maximum 5 tags (noise threshold)
- All lowercase, hyphen-separated within a segment
- Prefer reusing existing tags Brian already has in his vault
- Never invent tags that don't fit Brian's actual taxonomy (check entity index first)

## Safety rules for frontmatter

1. **`source: manual`** means Brian (or another human) wrote this by hand. Skill NEVER overwrites these notes.
2. **`source: obsidian-bridge-auto`** means the skill wrote this. Skill can overwrite, but only with Brian's consent.
3. **`memory-ref`** is immutable once written. If the underlying claude-mem observation is re-indexed with a new ID, the skill creates a NEW Obsidian note — never replaces the old one.
4. **`status: triaged`** signals Brian has reviewed it. Skill never touches triaged notes.

## Example: complete thread-part frontmatter

```yaml
---
type: thread-part
source: claude-session
created: 2026-04-22T15:45
owner: Brian
memory-ref: mem_a7f3b2c1
thread: t7a2-f9e8-4c31-b2d0-1a5f8c3e7b9d
thread-position: 2/3
entities: [[Project Alpha]], [[Sarah]]
tags: [domain/product, topic/churn, thought-type/hypothesis, state/open]
status: inbox
related-notes: [[2026-04-18-0930 - t4b9 - power-user-interview-patterns]]
---
```

## Example: cluster note frontmatter

```yaml
---
type: cluster
source: obsidian-bridge-auto
created: 2026-04-22T02:00
updated: 2026-04-22
owner: Brian
memory-ref: cluster_customer-retention
cluster-key: customer-retention
source-observations: 23
tags: [domain/product, topic/churn, topic/onboarding, meta/cluster]
status: auto-generated
previous-version: 00 - Clusters/.archive/Cluster - Customer Retention - 2026-04-15.md
---
```
