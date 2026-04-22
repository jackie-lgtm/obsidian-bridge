# Naming Conventions

## Filename pattern

```
YYYY-MM-DD-HHMM - {slug}.md
```

### Rules

- Date-time prefix is **required** — keeps Inbox chronologically sortable
- Use 24-hour time, local timezone
- Separator between timestamp and slug: ` - ` (space, hyphen, space)
- Slug is lowercase, kebab-case, 3–6 words
- Never include the user's private proper nouns (people, clients, internal project names) in the filename unless the user explicitly names them in the request

### Examples

Good:
- `2026-04-22-1730 - api-rate-limit-decision.md`
- `2026-04-22-0915 - onboarding-flow-notes.md`
- `2026-04-22-2245 - debugging-session-summary.md`

Bad:
- `Notes about the API.md` (no timestamp, title case, vague)
- `2026-04-22 - some-private-client-deal.md` (names a client)
- `claude-session.md` (no timestamp, no topic)

## Collision handling

If the generated filename already exists (rare, due to minute precision):
- First collision: append ` -2` before `.md` → `2026-04-22-1730 - api-notes -2.md`
- Continue incrementing: ` -3`, ` -4`, etc.
- Never overwrite an existing file

## Folder placement

Everything goes into `{vault}/{inbox_folder}/`. No subfolders inside Inbox — flat structure for easy triage. The user moves notes into organized folders after review.
