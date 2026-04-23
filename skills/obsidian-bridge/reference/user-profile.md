# The "About Brian" Profile Note

A single, auto-maintained note at `{vault}/About Brian.md` that summarizes what Claude knows about Brian. Loaded once per session as baseline context.

## Purpose

Give every future session a **500-token head start** on knowing who Brian is — his working style, active projects, people in his orbit, stable preferences. Without this, every session starts from zero and burns tokens rediscovering the same facts.

## Strict rule: 3+ confirmations

**Nothing goes into "About Brian" on a single mention.** A fact must be confirmed in claude-mem observations:
- 3+ times
- Across 2+ separate sessions
- With consistent phrasing (or close paraphrase)

This prevents the profile from filling up with Brian's in-the-moment thoughts that he'll change tomorrow.

## Schema

```markdown
---
type: profile
source: obsidian-bridge-auto
updated: 2026-04-22
confidence: high
---

# About Brian

## Working style
- {stable fact 1}
- {stable fact 2}

## Current projects (active)
- [[Project Name]] — {one-line description from claude-mem}

## People in Brian's orbit
- [[Person Name]] — {role or relationship}

## Preferences (stable, repeated)
- {preference 1}
- {preference 2}

## Constraints (things to never do)
- {constraint 1}
- {constraint 2}

## Tools & systems
- {tool 1}
- {tool 2}

## Open threads (things Brian said he wanted to come back to)
- [[related note]] — {one-line}

## Metadata
- Last rebuilt: 2026-04-22
- Source observations: 47 claude-mem observations
- Confidence: high / medium / low
```

## Sections — what belongs in each

### Working style
How Brian operates day-to-day. Examples:
- "Voice-first via Whisper AI"
- "Reviews Inbox before 10am"
- "ADHD-pattern, needs connection surfacing"

Never: one-off moods ("Brian was tired today" ❌).

### Current projects (active)
Projects Brian has mentioned in the last 30 days with a status of "active" (not "parked" or "done"). Auto-drops off if no mention for 30+ days. One line each. Links to the hub note if one exists.

### People in Brian's orbit
People Brian has mentioned 3+ times across 2+ sessions. Role/relationship only — no deep personal detail. Brian edits manually if he wants more.

### Preferences (stable, repeated)
Brian's explicit preferences, stated with words like "I prefer" / "I always" / "I never" / "I hate when." Must appear 3+ times.

### Constraints (things to never do)
Hard rules Brian has stated. Examples:
- "Never auto-send emails"
- "Never post to social media on my behalf"
- "Never share with Jackie's personal vault"

Even one clear statement here is enough — these are safety rules, not preferences.

### Tools & systems
Tools Brian uses consistently. Obsidian Sync, Claude Code, claude-mem, Whisper, etc.

### Open threads
Things Brian explicitly said he wanted to return to. Auto-clears when Brian marks the thread done (e.g., a triaged note that resolves it).

## Update protocol

Runs **weekly** (or on-demand via `scripts/build-entity-index.sh --profile`).

1. Query claude-mem for observations about Brian himself (working style, preferences, constraints)
2. Filter to facts with 3+ confirmations across 2+ sessions
3. Diff against current "About Brian.md"
4. **Show the diff to Brian** — this is a consent point
5. On approval, write the update. On rejection, log the rejection to avoid re-suggesting.

## Manual overrides

Brian can edit "About Brian.md" manually anytime. The skill detects manual edits via frontmatter:
- If `source: manual` or `source: user-edit` — skill never overwrites
- If `source: obsidian-bridge-auto` — skill can update with consent

If Brian adds a section like `## My rules` manually, the skill preserves it forever.

## What "About Brian" is NOT

- Not a journal (no daily entries)
- Not a decision log (decisions live in their own notes)
- Not a relationship tracker (people have their own notes)
- Not a full history (it's a snapshot, not a timeline)

Keep it **short** (ideally ≤ 500 words). The moment it grows past that, tighten it.

## Privacy

"About Brian" stays local. It's:
- In Brian's vault (synced via Obsidian Sync to Brian's own iCloud/devices)
- Not transmitted to any external service by this skill
- Not visible to anyone who doesn't have access to Brian's vault

## Why load it every session?

Because it costs ~500 tokens once and saves thousands later:
- Claude knows Brian's project names without asking
- Claude respects Brian's constraints without re-discovering them
- Claude surfaces the right connections because it knows the context

This is the foundation of low-token, high-recall memory.
