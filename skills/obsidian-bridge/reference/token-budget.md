# Token Budget & Tiered Retrieval

This doc defines how obsidian-bridge keeps memory operations cheap during conversation. The goal: **≤ 500 tokens per turn** spent on memory, on average.

## Why it matters

Brian is voice-first and talks a lot. If every turn does a full semantic search + loads 3 related notes, each turn easily costs 3000+ tokens on memory alone. Across a 30-minute conversation, that's 50K+ tokens burned on overhead.

With tiered retrieval, most turns cost < 100 tokens on memory. Brian gets the same recall at 10× less cost.

## The retrieval tiers

```
Tier 0: Entity index (string match)         ~0 tokens
Tier 1: Index 1-liner summary               ~40 tokens
Tier 2: claude-mem search, limit 1          ~150 tokens
Tier 3: claude-mem timeline (context)       ~400 tokens
Tier 4: Full observation content            ~1000 tokens
Tier 5: Full Obsidian note (Read)           variable
```

## Turn-by-turn protocol

### Default turn (no memory work)

If Brian's turn does not mention any known entity AND is not asking a memory question:
- **Zero retrieval.** Just respond to his actual request.
- Cost: 0 memory tokens.

### Entity detected (referral opportunity)

- **Tier 0 + Tier 1.** String match against entity index, then 1-line surface.
- Cost: ~40 tokens.
- Response includes a one-line `↪` referral at the end.

### Brian engages with referral ("yes, pull it up")

- **Tier 2.** Call `mcp__plugin_claude-mem_mcp-search__search` with `limit: 1`.
- Cost: ~150 tokens.
- Response: a brief summary of the most recent relevant observation.

### Brian asks for refresh ("what was the context again?")

- **Tier 3.** Call `mcp__plugin_claude-mem_mcp-search__timeline` with anchor, `depth_before: 2`, `depth_after: 2`.
- Cost: ~400 tokens.
- Response: surrounding context around the anchor observation.

### Brian asks for the actual note ("pull up the note")

- **Tier 4 or 5.** Either `get_observations` (if he wants the memory) or `Read` (if he wants the Obsidian note).
- Cost: ~1000 tokens (or more for long notes).
- Response: full content.

## The escalation rule

**Never skip tiers.** Going straight to Tier 4 when a Tier 1 answer would suffice is the #1 token waste.

Wrong:
```
Brian: "Did we talk about Project Alpha recently?"
Claude: [loads full content of 3 Obsidian notes + 5 observations — 6000 tokens]
```

Right:
```
Brian: "Did we talk about Project Alpha recently?"
Claude: [Tier 1 lookup — 40 tokens]
        "Yes — 14 mentions, last was Apr 18 about the auth decision. Want the details?"
Brian: "yes"
Claude: [Tier 2 — 150 tokens]
        "Here's the summary: {...}"
```

## Session startup cost

One-time per session:
- Entity index: ~100 tokens
- "About Brian": ~400 tokens
- **Total startup: ~500 tokens**

After that, per-turn memory cost is usually 0-40 tokens.

## When NOT to retrieve

Even if an entity matches, skip retrieval when:
1. Brian is in execution mode (giving a direct command to Claude). He doesn't need a referral while he's working.
2. Brian has already referenced this entity earlier in the current session. Don't repeat yourself.
3. The match is ambiguous (generic word, multiple possible entities). Better to ask Brian than guess wrong.
4. The retrieval would cost more than 200 tokens and Brian didn't ask for deep context.

## When to escalate aggressively

Some turns warrant higher retrieval despite the budget:
- Brian explicitly asks "what did I say about X last time?"
- Brian is making a decision that clearly depends on past context
- Brian is about to repeat work he's already done (Claude can warn him)

In these cases, jump straight to Tier 2 or 3. Token cost is justified by the value.

## Caching within a session

- Entity index: loaded once, referenced all session
- "About Brian": loaded once, cached
- Any observation pulled at Tier 2+: cached for the rest of the session (don't re-query)
- Any Obsidian note read: cached for the rest of the session

**Cache invalidation:** if Brian edits a note during the session, Claude flushes the cache for that note. If Brian explicitly says "refresh," flush everything.

## Measurement

The skill does not auto-track token usage (that'd be recursive overhead). But Brian can ask:
- "How much memory have you pulled in this session?"
- Claude gives an honest rough estimate based on what operations it actually performed.

## The point

Brian's conversations are long. Memory is Brian's biggest value driver. Budget it like a scarce resource and spend it where it actually helps him — not on speculative retrievals he didn't ask for.
