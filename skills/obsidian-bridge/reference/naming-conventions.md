# Naming Conventions

## Filename pattern

```
YYYY-MM-DD-HHMM - {thread-short-id} - {slug}.md
```

### Parts

- **Timestamp**: `YYYY-MM-DD-HHMM`, local timezone, 24-hour. Required.
- **Thread short ID**: 4-character identifier. Groups atomic notes from the same voice stream. Omit for single-note captures (use `single` as placeholder or skip the segment entirely).
- **Slug**: lowercase, kebab-case, 3–6 words describing the idea.

### Thread short ID

- Format: `t` + 3 hex chars (e.g., `t7a2`, `tb91`, `tc04`)
- Generated from the first 4 chars of the full thread UUID in frontmatter
- All atomic notes from one voice message share this ID
- Makes it instantly visible which notes belong together

### Examples

Single-note capture (Brian typed / said one idea):
```
2026-04-22-1730 - single - api-rate-limit-decision.md
```

3-note thread from a voice message at 3:45 PM:
```
2026-04-22-1545 - t7a2 - customer-churn-observation.md
2026-04-22-1545 - t7a2 - root-cause-onboarding-friction.md
2026-04-22-1545 - t7a2 - proposed-fix-guided-tour.md
```

Cluster note (auto-generated, different naming):
```
00 - Clusters/Cluster - Customer Retention.md
00 - Clusters/Cluster - Project Alpha.md
```

Profile note (single, fixed name):
```
About Brian.md
```

## Slug rules

- Lowercase, kebab-case
- 3–6 words ideal
- Focus on the **idea**, not the speaker or context
- Never include the user's private proper nouns (client names, internal project codenames) unless Brian explicitly named them
- Never use filler words: "note", "thought", "idea", "about"

### Good slugs
- `customer-churn-observation`
- `api-rate-limit-decision`
- `onboarding-friction-hypothesis`
- `power-user-interview-patterns`

### Bad slugs
- `some-notes-about-the-thing` (vague)
- `idea-1` (no content signal)
- `client-x-private-deal` (names a private entity without permission)
- `brian-says-churn-is-high` (describes speaker, not idea)

## Collision handling

Collisions are rare (minute precision + thread ID). If one happens:
- Append ` -2`, ` -3`, etc. before `.md`
- Example: `2026-04-22-1545 - t7a2 - same-slug -2.md`
- **Never overwrite.**

## Special filenames (reserved)

These names are reserved for auto-generated skill files. Brian can edit them but the skill may overwrite on its next rebuild (with consent):

- `About Brian.md` — the profile note
- `00 - Clusters/Cluster - *.md` — cluster notes
- `99 - Inbox/*.md` — everything written by the skill

All other filenames in the vault are **user-owned** and the skill never touches them.
