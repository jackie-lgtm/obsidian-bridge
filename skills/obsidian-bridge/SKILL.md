---
name: obsidian-bridge
description: A conversational memory referral system for Brian. Uses claude-mem as the canonical memory store and Obsidian as the human-readable interface. Proactively surfaces connections during voice-driven conversations, writes atomic notes to an Inbox, and maintains bidirectional links between claude-mem observations and Obsidian notes. Designed for ADHD-pattern thinkers who speak long voice streams through Whisper AI — optimized for low token cost and strong memory recall. Load this skill whenever Brian is having a working conversation (not just when he says "save to Obsidian") so it can surface connections in real time.
---

# Obsidian Bridge — Brian's Memory Referral System

## What this skill IS

A **conversational memory referral system**. The job is not just to save notes. The job is to make Brian's memory **work for him** during conversations:

1. **Listen** for entities Brian mentions (people, projects, concepts, decisions)
2. **Match** them against claude-mem and the Obsidian vault, cheaply
3. **Surface** relevant past context inline, without derailing him
4. **Capture** new thoughts as atomic Obsidian notes, linked to claude-mem observations
5. **Maintain** a lightweight "About Brian" profile that makes every future session smarter

## The user: Brian

- **Voice-first.** Uses Whisper AI to talk to Claude. Long spoken streams, not typed messages.
- **ADHD-pattern thinker.** Rapid topic jumps. Associative. Non-linear. Often leaves threads open.
- **Older learner, actively curious.** Wants to build, not just capture.
- **Talks a lot.** Expect 500–2000 word voice inputs per turn. Expect rambling.

**Design consequence:** Brian's brain moves fast. The skill has to keep up **without costing tokens**. Retrieval must be cheap. Saving must be silent (no long previews interrupting flow). Connection-surfacing must be subtle.

## Architecture — the three stores

```
┌─────────────────────┐   writes     ┌─────────────────────┐
│                     │ ───────────► │                     │
│   claude-mem        │              │  Obsidian vault     │
│   (canonical memory)│ ◄─────────── │  (human interface)  │
│   SQLite + vectors  │   ref-links  │  Bryan Brain        │
│                     │              │                     │
└─────────────────────┘              └─────────────────────┘
           ▲                                   ▲
           │                                   │
           │          ┌──────────────┐         │
           └──────────│ Entity Index │─────────┘
                      │ (cheap!)     │
                      │ ~5KB JSON    │
                      └──────────────┘
```

- **claude-mem** = canonical memory. Auto-captures everything. SQLite + vector search. Fast semantic lookup.
- **Obsidian vault** = Brian's conscious interface. Human-readable, graph-navigable, in his hands.
- **Entity Index** = a tiny JSON file (`~/.claude/obsidian-bridge.entities.json`) that maps names/aliases to (claude-mem obs IDs, Obsidian note paths). This is how we achieve cheap retrieval.

**Bidirectional invariant:** Every Obsidian note has `memory-ref: <obs-id>` in frontmatter. Every claude-mem observation stored by this skill has an `obsidian_path` field. **No orphans in either direction.**

## Prerequisites (hard)

- **claude-mem plugin MUST be installed.** This skill is a hard dependency on claude-mem.
- If `mcp__plugin_claude-mem_mcp-search__*` tools are not available, the skill refuses to run and instructs Brian to install claude-mem first.

## Configuration

Located at `~/.claude/obsidian-bridge.config.json`:

```json
{
  "vault_name": "Bryan Brain",
  "vault_path": "/Users/brian/Library/Mobile Documents/iCloud~md~obsidian/Documents/Bryan Synced Brain/Bryan Brain",
  "inbox_folder": "99 - Inbox",
  "clusters_folder": "00 - Clusters",
  "profile_note": "About Brian.md",
  "owner": "Brian",
  "surfacing_mode": "inline",
  "token_budget_per_turn": 500,
  "atomic_splitting": "aggressive"
}
```

## Session startup protocol (runs ONCE per conversation)

At the start of every session where this skill is loaded:

1. **Load the entity index** (`obsidian-bridge.entities.json`). Small file, cheap.
2. **Load "About Brian"** from the vault. Usually < 1KB. Cache it for the session.
3. **Do NOT pre-fetch** any session summaries, notes, or observations beyond those two files.

That's it. Session starts with ~1KB of memory context loaded. Anything more is pulled on demand.

## During conversation — the referral protocol

### Step 1: Entity detection (every turn, cheap)

While Brian is talking, scan his input for entities that match the entity index:
- Proper nouns (people, companies, places)
- Project names
- Concepts Brian has previously discussed
- Decision topics

Use substring + alias matching against the entity index. **No LLM call needed** — this is regex/string matching against a small JSON.

### Step 2: Surface connections inline (ADHD-friendly)

When a known entity is detected, surface the connection **briefly and non-disruptively** at the end of the response:

> ↪ *You mentioned **Project Alpha** — last context: decision on auth approach, Apr 18. Pull it up?*

Rules:
- One line, prefixed with `↪` so Brian can visually scan/ignore
- Include the **most recent** relevant context, not everything
- Offer to pull more, don't force it
- Never interrupt Brian mid-thought

### Step 3: Progressive retrieval (only if Brian engages)

If Brian says "yes, pull it up" or similar:
1. First pull the 1-line summaries of matching observations/notes (cheap — ~100 tokens)
2. If he wants more, pull the full note or observation content
3. Never jump straight to full content. Summary first, always.

This is the **tiered retrieval** system. See `reference/token-budget.md`.

## Capturing new thoughts — atomic notes

### When Brian says "save this" / "log this" / "capture this"

Or when he signals intent without saying it outright (e.g., "okay I just realized…" followed by an insight).

### Atomic splitting (for voice streams)

Brian will spray 5–10 ideas in a single voice message. The skill splits them into **atomic notes** — one note per distinct idea — linked together as a "thought chain."

**Splitting rules:**
- A distinct idea = a statement that stands on its own and is worth retrieving independently
- Supporting detail stays inside its parent atomic note as bullets
- Each atomic note gets its own filename + frontmatter + memory-ref
- The thought chain is preserved via `thread` frontmatter field (shared UUID) + explicit `[[next]]` / `[[prev]]` wiki-links

See `reference/voice-to-atomic.md` for the full algorithm.

### Filename pattern

```
YYYY-MM-DD-HHMM - {thread-short-id} - {slug}.md
```

Example (a 3-note thread from one voice message at 3:45 PM):
```
2026-04-22-1545 - t7a2 - customer-churn-observation.md
2026-04-22-1545 - t7a2 - root-cause-onboarding-friction.md
2026-04-22-1545 - t7a2 - proposed-fix-guided-tour.md
```

The `t7a2` is a short thread ID — all notes from the same voice message share it, so Brian can find the full thought chain instantly.

### Frontmatter (required on every note)

```yaml
---
type: session | insight | decision | task | reference | person | project | thread-part
source: claude-session
created: 2026-04-22T15:45
owner: Brian
memory-ref: mem_<observation-id>       # REQUIRED — bidirectional link
thread: t7a2-<full-uuid>               # groups atomic notes from same voice stream
thread-position: 2/3                   # this note is #2 of 3 in the thread
entities: [[Project Alpha]], [[Sarah]] # auto-extracted, wiki-linked
tags: [domain/product, topic/churn]
status: inbox
---
```

### Body template (short, scannable, ADHD-friendly)

```markdown
# {One-sentence title}

> {The single core idea, in Brian's voice, 1-2 sentences}

**Why it matters:** {one line, optional}

**Connects to:**
- [[previous atomic note in thread]]
- [[next atomic note in thread]]
- [[related Obsidian note from past session]]

**Memory:** `mem_<observation-id>`
```

**Maximum 120 words of body.** If it's longer, it's not atomic — split it again.

## Silent-write mode for voice flow

Brian is talking. Interrupting him with a "Write this? yes/no?" prompt every 30 seconds will break his flow.

**New default: silent-write into Inbox, batch-confirm at natural pauses.**

Rules:
- During active voice input, Claude silently drafts atomic notes into memory (not yet written to disk)
- At a natural pause (Brian asks a question, explicitly changes topic, or says "okay"), Claude shows a **batch summary**:
  > 📝 Captured 4 atomic notes from the last 3 minutes — thread `t7a2`. Write to Inbox?
- Brian approves the batch with `yes` / `write` / `save` — single approval covers all notes in the batch
- Brian can reject with `no` / `scrap` — all drafts discarded
- Brian can selectively keep with `keep 1, 3` — only notes 1 and 3 saved

This is still explicit user consent, just batched. See `reference/voice-to-atomic.md` for the full flow.

## Clusters (auto-surfaced thought groupings)

Weekly (or on demand), the skill generates **cluster notes** in `{vault}/00 - Clusters/` that show Brian his current thought groupings.

**What a cluster note looks like:**

```markdown
---
type: cluster
source: obsidian-bridge-auto
updated: 2026-04-22
cluster-key: customer-retention
---

# 🧭 Cluster: Customer Retention

**Why this is a cluster:** 23 observations across 11 sessions mention customer retention or churn.

## Thought threads
- [[2026-04-22-1545 - t7a2 - customer-churn-observation]] → [[root-cause-onboarding-friction]] → [[proposed-fix-guided-tour]]
- [[2026-04-18-0930 - t4b9 - power-user-interview-patterns]]
- [[2026-04-10-1100 - t2c1 - churn-model-vs-lifecycle-stage]]

## People mentioned
- [[Sarah (Customer Success)]]
- [[Marcus (Analytics)]]

## Open questions
- Does the guided-tour fix address the specific friction identified in Marcus's data?
- How do power-user interview patterns change what we prioritize?

## Recent decisions
- [[2026-04-18 - decision - prioritize onboarding over pricing experiments]]
```

Clusters are **read-only for Brian** — generated by the skill, not manually edited. They're Brian's way to *see his own thinking* at a glance.

Clustering algorithm: group notes by shared `entities`, co-occurring `tags`, and claude-mem vector similarity. See `reference/referral-system.md`.

## The "About Brian" profile note

Lives at `{vault}/About Brian.md`. Auto-maintained by the skill.

**What goes in it (stable facts only — 3+ reinforcements in claude-mem):**

```markdown
---
type: profile
source: obsidian-bridge-auto
updated: 2026-04-22
---

# About Brian

## Working style
- Voice-first via Whisper AI
- ADHD-pattern; needs connection-surfacing
- Prefers atomic notes over long docs

## Current projects (active)
- [[Project Alpha]] — {one-line}
- [[Project Beta]] — {one-line}

## People in Brian's orbit
- [[Sarah]] — Customer Success
- [[Marcus]] — Analytics

## Preferences (stable, repeated)
- Morning routine: reviews Inbox before 10am
- Writing style: short sentences, bullets over paragraphs
- Never: auto-send emails, auto-post to social

## Tools & systems
- Obsidian Sync (paid)
- Claude Code + claude-mem
- ...

## DO NOT update without 3+ confirmations
Any fact added here must appear in claude-mem observations 3+ times across 2+ sessions.
```

Loaded once per session, cached in context. ~500 tokens, permanent baseline.

## Token budget

Target: **≤ 500 tokens/turn on memory operations** during normal conversation.

| Operation | Token cost | When |
|---|---|---|
| Load entity index | ~100 | Once per session |
| Load "About Brian" | ~400 | Once per session |
| Entity detection per turn | 0 (string match, no LLM) | Every turn |
| Surface connection (1-line) | ~40 | When entity detected |
| Pull summary on demand | ~100-200 | Only if Brian engages |
| Pull full note on demand | ~500-2000 | Only if Brian asks for detail |
| Draft atomic notes (silent) | variable | During voice streams |
| Batch-confirm draft notes | ~200 | At natural pause |

See `reference/token-budget.md` for details.

## Write policy (strict, unchanged)

1. Writes ONLY to `{vault}/{inbox_folder}/` and `{vault}/{clusters_folder}/` and the single `About Brian.md` file
2. Never modifies user-owned notes in the vault (any note without `source: obsidian-bridge-auto` frontmatter)
3. Never reads files outside Inbox unless Brian explicitly asks for a specific note
4. Never reads other vaults on the machine
5. Never transmits vault content outside the local machine

## Explicit consent points

Despite silent drafting, explicit consent is still required for:
- **Batch write** to Inbox (Brian approves each batch)
- **Cluster generation** (Brian approves first cluster run; subsequent runs are weekly auto unless he opts out)
- **"About Brian" updates** (shown as diff, Brian approves each change)
- **Reading a specific existing note** outside Inbox

## Reference files

- `reference/referral-system.md` — entity index schema + clustering algorithm
- `reference/voice-to-atomic.md` — how voice streams are split into atomic notes
- `reference/user-profile.md` — "About Brian" maintenance rules
- `reference/token-budget.md` — tiered retrieval protocol
- `reference/naming-conventions.md` — filename rules
- `reference/frontmatter-schema.md` — YAML schema
- `reference/folder-structure.md` — recommended vault layout

## Scripts

- `scripts/resolve-vault.sh` — find vault path by name (macOS only)
- `scripts/build-entity-index.sh` — rebuild entity index from claude-mem + vault (run weekly or on demand)

## What this skill will NEVER do

- Write without explicit (batched) consent
- Modify Brian's hand-written notes
- Read vaults other than the configured one
- Upload vault content anywhere
- Bulk-reorganize Brian's existing notes
- Create connections Brian hasn't actually made (no hallucinated wiki-links)
- Update "About Brian" based on a single mention
