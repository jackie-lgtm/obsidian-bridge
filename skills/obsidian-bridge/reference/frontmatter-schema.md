# Frontmatter Schema

All notes written by obsidian-bridge MUST have YAML frontmatter at the top of the file.

## Required fields

```yaml
---
type: session | insight | decision | task | reference | person | project
source: claude-session
created: 2026-04-22T17:30
owner: Brian
session-topic: short description of what the session was about
tags: [tag1, tag2]
status: inbox
---
```

### Field definitions

| Field | Type | Description |
|---|---|---|
| `type` | enum | Primary classification. Pick the best-fit from the enum. |
| `source` | string | Always `claude-session` for notes written by this skill. |
| `created` | ISO 8601 | Datetime the note was written, local timezone, no seconds needed. |
| `owner` | string | Human who owns this vault (from config). |
| `session-topic` | string | 5–15 word description of what the conversation was about. |
| `tags` | list | 2–5 tags. Prefer lowercase, hyphen-separated. |
| `status` | enum | Always `inbox` for new notes. User changes to `triaged` / `archived` after review. |

## Optional fields

```yaml
session-id: 0e3f4a5b-...              # claude-mem session ID, if claude-mem is installed
related-notes: [[Note A]], [[Note B]] # only if user referenced them explicitly
decision: accepted | rejected | deferred  # for type: decision
project: AJ Projects | Anima | Revive | Aurora  # if clearly scoped
priority: low | medium | high | urgent
```

## Type reference

- **session** — a conversation-level summary. Default if unsure.
- **insight** — a single realization worth remembering.
- **decision** — a recorded choice, with context and rationale.
- **task** — a todo-like note. Brian processes these into his task system.
- **reference** — reusable knowledge (how-to, config, snippet).
- **person** — notes about a specific person from a conversation.
- **project** — project-scoped notes.

## Tag guidelines

- Use lowercase, hyphen-separated: `#api-design` not `#API Design`
- Prefer existing tags in the vault if Claude has observed them in this session
- Start with 2 tags minimum, 5 maximum
- Include a "domain" tag (`#engineering`, `#biz-ops`, `#personal`) and a "topic" tag (`#authentication`, `#hiring`, `#billing`)

## Example complete frontmatter

```yaml
---
type: decision
source: claude-session
created: 2026-04-22T17:30
owner: Brian
session-topic: Chose JWT over session cookies for API auth
tags: [engineering, authentication, api-design]
status: inbox
decision: accepted
project: AJ Projects
priority: medium
---
```
