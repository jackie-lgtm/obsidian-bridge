# obsidian-bridge

A conversational memory referral system for Claude Code users who think and talk fast.

**What it does:**
- Makes your past conversations *findable* — surfaces relevant memory inline during live chat
- Captures voice streams as atomic, linked Obsidian notes (not walls of text)
- Maintains a lightweight "About Brian" profile note so every session starts with context
- Builds auto-generated "Cluster" notes that show you your own thought groupings
- Does it all on a ~500-token-per-turn budget

**Built for:** voice-first, ADHD-pattern thinkers who use Whisper AI + Claude Code and need their memory system to keep up without burning tokens.

## Architecture

```
┌─────────────────────┐   writes     ┌─────────────────────┐
│   claude-mem        │ ───────────► │  Obsidian vault     │
│   (canonical memory)│ ◄─────────── │  (human interface)  │
│   SQLite + vectors  │   ref-links  │  Bryan Brain        │
└─────────────────────┘              └─────────────────────┘
           ▲                                   ▲
           │          ┌──────────────┐         │
           └──────────│ Entity Index │─────────┘
                      │ ~5KB JSON    │
                      └──────────────┘
```

- **claude-mem** — canonical memory, auto-captures every session
- **Obsidian** — human-readable interface, graph-navigable
- **Entity Index** — tiny JSON file for cheap-as-free retrieval during chat

Every Obsidian note has `memory-ref: mem_<id>` in frontmatter. Every claude-mem observation can link back to its Obsidian note. **No orphans in either direction.**

## Prerequisites

| Requirement | Why |
|---|---|
| **Claude Code** | Host |
| **claude-mem plugin** (`thedotmack/claude-mem`) | **Hard dependency.** The skill refuses to run without it. |
| **Obsidian** + any vault | Where notes are written |
| **macOS** | The vault resolver script is macOS-specific |
| **Obsidian Sync** ($5/mo) *recommended* | Keeps vault synced across devices independent of iCloud |

## Install

### 1. Install claude-mem first (required)

```
/plugin marketplace add thedotmack/claude-mem
/plugin install claude-mem
```

Restart Claude Code.

### 2. Install obsidian-bridge

```
/plugin marketplace add <path-or-url-to-this-repo>
/plugin install obsidian-bridge
```

Restart Claude Code.

### 3. First-run setup

The first time you ask Claude to save something to Obsidian, it will prompt you for:
- Your vault name (e.g., `Bryan Brain`)
- The absolute path to your vault

Claude writes config to `~/.claude/obsidian-bridge.config.json`.

Example config:

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

### 4. Build the entity index (first time)

After you've had at least one conversation, run:

```bash
~/.claude/plugins/cache/*/obsidian-bridge/*/skills/obsidian-bridge/scripts/build-entity-index.sh
```

This builds `~/.claude/obsidian-bridge.entities.json` from your claude-mem observations + vault frontmatter.

### 5. (Recommended) Set up weekly entity index rebuild

Add a launchd job or cron to rebuild weekly. Example cron:
```bash
0 2 * * 0  ~/.../skills/obsidian-bridge/scripts/build-entity-index.sh
```

## How to use it

### Save a note during conversation

```
> Okay, capture this — I think the churn spike is from onboarding friction
  specifically step 3 where people have to configure SSO, and we should
  just skip it for trials.
```

Claude silently drafts atomic notes. At the next natural pause:

```
📝 Captured 3 atomic notes (thread t9k4):
  1. Churn spike hypothesis: onboarding friction
  2. Specific friction point: SSO config at step 3
  3. Proposed fix: skip SSO for trials

Write all to Inbox? (yes / keep 1,3 / scrap)
```

You say `yes`, they land in `Bryan Brain/99 - Inbox/`. Triage them when you want.

### Get a memory referral during chat

```
> What was the deal with Project Alpha's auth decision?
```

Claude:
```
We landed on JWT tokens in the Apr 18 session. Key context: Sarah's team
needed stateless scaling, Marcus flagged the mobile refresh-token issue.
The decision note is [[2026-04-18 - decision - auth-jwt]].

↪ Pull up the full decision note? Or the surrounding thread?
```

(Notice: minimal retrieval, offers escalation, never pre-fetches full notes.)

### See your thought clusters

Open `Bryan Brain/00 - Clusters/` in Obsidian. You'll see notes like:
- `Cluster - Customer Retention.md`
- `Cluster - Project Alpha.md`
- `Cluster - Team Hiring.md`

Each one shows:
- **Thought threads** — linked chains of atomic notes
- **People mentioned** — wiki-linked
- **Open questions** — things you raised but didn't resolve
- **Recent decisions** — what you actually decided

These are **auto-generated weekly**. They are your thinking, surfaced back to you.

## Safety guarantees

This skill will **never**:
- ❌ Modify your hand-written notes (`source: manual` is untouchable)
- ❌ Write outside `99 - Inbox/`, `00 - Clusters/`, or `About Brian.md`
- ❌ Read notes in other vaults on your machine
- ❌ Upload your vault to any remote service
- ❌ Bulk-reorganize your existing notes
- ❌ Create hallucinated wiki-links (only links entities you actually referenced)
- ❌ Update "About Brian" based on a single off-hand mention (requires 3+ confirmations)

## Token budget

| Operation | Cost | Frequency |
|---|---|---|
| Session startup (index + profile) | ~500 tokens | Once per conversation |
| Entity detection per turn | 0 tokens (string match) | Every turn |
| Inline referral (when entity matches) | ~40 tokens | On detection |
| Summary lookup (tier 2) | ~150 tokens | Only when you engage |
| Full context (tier 3+) | 400-2000 tokens | Only on explicit ask |

Target: **≤ 500 tokens per turn on memory operations.**

## File structure

```
obsidian-bridge/
├── README.md
├── plugin.json
├── marketplace.json
└── skills/
    └── obsidian-bridge/
        ├── SKILL.md                       ← main skill definition
        ├── reference/
        │   ├── referral-system.md         ← entity index + clustering
        │   ├── voice-to-atomic.md         ← voice → atomic notes
        │   ├── user-profile.md            ← About Brian maintenance
        │   ├── token-budget.md            ← tiered retrieval protocol
        │   ├── naming-conventions.md      ← filename rules
        │   ├── frontmatter-schema.md      ← YAML schema + tag taxonomy
        │   └── folder-structure.md        ← vault layout
        └── scripts/
            ├── resolve-vault.sh           ← find vault path by name
            └── build-entity-index.sh      ← rebuild entity index from claude-mem + vault
```

## Versioning

- `0.2.0` — Full referral system architecture. Bidirectional claude-mem ↔ Obsidian. Voice-to-atomic note splitting. About Brian profile. Cluster auto-generation. Token-budgeted retrieval.
- `0.1.0` — Initial scaffold (simple Inbox-only writer).

## License

MIT
