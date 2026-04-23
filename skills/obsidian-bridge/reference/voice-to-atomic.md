# Voice Streams → Atomic Notes

How obsidian-bridge converts Brian's long Whisper voice messages into short, linked, atomic Obsidian notes.

## The problem

Brian talks. A lot. A single voice message might be 1500 words containing 8 distinct ideas that jump between 3 topics. If we save it as one big note, it's useless for retrieval. If we miss the jumps, the graph is noise.

## The algorithm

### Step 1: Detect idea boundaries

Scan Brian's voice input for signals that mark a new idea:

**Explicit markers:**
- "okay so" / "alright" / "so then"
- "another thing" / "also"
- "oh wait" / "actually"
- "moving on" / "different topic"
- "and speaking of" / "which reminds me"

**Implicit markers:**
- Topic shift detected via semantic similarity (new paragraph ≠ old paragraph)
- Named entity change (Project A → Project B)
- Question → statement shift
- Past tense → future tense shift (recalling vs. planning)

### Step 2: Extract the core idea of each segment

For each segment:
1. Identify the **single claim** it's making (1-2 sentences)
2. Extract supporting detail as bullets
3. Identify entities mentioned (people, projects, concepts)
4. Tag with domain + topic

### Step 3: Build the thread

All atomic notes from the same voice message share:
- **Thread UUID** (e.g., `t7a2-f9e8-4c31-b2d0-1a5f8c3e7b9d`) — in frontmatter
- **Thread short ID** (first 4 chars, e.g., `t7a2`) — in filename
- **Timestamp** — all notes share the same `YYYY-MM-DD-HHMM` prefix

Each atomic note in the thread has:
- `thread-position: N/M` — its place in the original flow
- Wiki-links to `[[prev]]` and `[[next]]` notes in the thread
- Wiki-links to related entities

### Step 4: Link across threads (the graph)

During draft:
- For each entity mentioned in the atomic note, check the entity index
- If the entity has prior notes, add a `[[related]]` wiki-link to the most recent one
- Do NOT link to notes that weren't actually referenced — no hallucinated connections

## Silent-write flow

```
Brian starts talking (voice)
   │
   ▼
Claude transcribes (via Whisper, already handled outside skill)
   │
   ▼
Skill detects: "this is a capture-worthy voice stream"
   │
   ▼
┌─────────────────────────────────────────────────┐
│  DRAFT PHASE (silent)                           │
│  - Split into atomic ideas                      │
│  - Build frontmatter + body for each            │
│  - Hold in memory, NOT written to disk          │
│  - Show nothing to Brian yet                    │
└─────────────────────────────────────────────────┘
   │
   ▼
Brian pauses (asks a question / changes topic / says "okay")
   │
   ▼
┌─────────────────────────────────────────────────┐
│  BATCH CONFIRM PHASE                            │
│  Show Brian:                                    │
│                                                 │
│  📝 Captured 4 atomic notes (thread t7a2):     │
│  1. Customer churn observation                  │
│  2. Root cause: onboarding friction             │
│  3. Proposed fix: guided tour                   │
│  4. Related decision from Apr 18                │
│                                                 │
│  Write all to Inbox? (yes / keep 1,3 / scrap)   │
└─────────────────────────────────────────────────┘
   │
   ▼
Brian: "yes" → write all to Inbox, silent confirm
Brian: "keep 1, 3" → write only 1 and 3, discard the rest
Brian: "scrap" → discard everything
Brian: doesn't respond → hold drafts for this session, ask again at next pause
```

## What counts as a "natural pause"?

- Brian asks Claude a direct question
- Brian shifts from monologue to dialogue ("what do you think?")
- Brian explicitly says "okay" / "alright" / "that's it" / "done"
- 60+ seconds of silence (if using streaming voice input)
- Brian issues a command ("let's move on", "save those", "what's next")

## What counts as "capture-worthy" in the first place?

Not everything Brian says should be captured. The skill only starts drafting when:
- Brian says an explicit save phrase ("capture this", "save that", "log it")
- **OR** Brian uses an insight marker ("I just realized", "the thing is", "here's what's interesting")
- **OR** Brian makes a decision statement ("we should", "I'm going to", "let's do X")
- **OR** Brian surfaces a new named entity (new person, new project, new concept)

Casual chat, questions to Claude, and execution commands are NOT captured unless Brian explicitly asks.

## Size discipline

Enforced per atomic note:
- Title: ≤ 80 characters
- Body: ≤ 120 words
- Max 3 `[[related]]` links per note (noise threshold)
- Max 5 tags per note

If a draft exceeds these limits, re-split. If it can't be re-split, flag it as `type: session` (a longer-form note) rather than `thread-part`.

## Edge cases

### Brian tells a long story with no clear idea

Save the whole story as one `type: session` note, not as atomic notes. Long narrative belongs together.

### Brian changes his mind mid-voice-stream

E.g., "we should do X... actually no, let's do Y." The skill saves the final statement (Y) as the idea, but preserves the reasoning ("considered X first, chose Y because...") in the body.

### Brian is just thinking out loud, not wanting to save

If no save markers fire and no decision/insight markers fire, the skill does **nothing**. Silent means silent — no drafting, no surfacing, no batch-confirm.

### Brian rejects a batch mid-conversation

Drafts are discarded. The original entities and claude-mem observations still exist (claude-mem auto-captures regardless). Brian can always retrieve later via `/search` even if he rejected the Obsidian write.

## Why this matters

For an ADHD-pattern voice-first user:
- **Silence = safety.** No interruption mid-thought.
- **Batch = control.** Brian confirms on his own terms.
- **Atomic = findable.** Each idea is its own node, not buried in a wall of text.
- **Linked = context.** The thread is preserved even when notes are scattered.
