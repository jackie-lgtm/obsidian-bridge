---
description: Rebuild the obsidian-bridge entity index and propose updates to clusters and the About Brian profile note. All changes require explicit approval.
argument-hint: "[--dry-run] [--profile-only] [--index-only]"
allowed-tools: Bash(~/.claude/plugins/*/skills/obsidian-bridge/scripts/build-entity-index.sh:*), Read, Edit, Write, Glob, Grep, mcp__plugin_claude-mem_mcp-search__search, mcp__plugin_claude-mem_mcp-search__get_observations, mcp__plugin_claude-mem_mcp-search__timeline
---

# /memory-rebuild

Rebuilds the memory referral system for obsidian-bridge. Three things happen, in order, each requiring explicit user approval:

1. **Entity index rebuild** — scans claude-mem + the vault, regenerates `~/.claude/obsidian-bridge.entities.json`
2. **Cluster proposals** — identifies new or changed thought clusters, shows diffs, writes approved ones to `{vault}/00 - Clusters/`
3. **About Brian update** — identifies stable facts with 3+ confirmations, shows a diff, writes approved changes to `{vault}/About Brian.md`

## Arguments

- `--dry-run` — show what would change, write nothing
- `--profile-only` — skip steps 1 and 2, only update the profile note
- `--index-only` — skip steps 2 and 3, only rebuild the entity index

## Workflow

### Step 1: Rebuild entity index

Find the obsidian-bridge plugin install path and run its entity-index script:

```bash
SCRIPT=$(ls ~/.claude/plugins/*/skills/obsidian-bridge/scripts/build-entity-index.sh 2>/dev/null | head -1)
if [[ -z "$SCRIPT" ]]; then
  echo "error: obsidian-bridge plugin not found in ~/.claude/plugins/"
  exit 1
fi
"$SCRIPT" $ARGUMENTS
```

Capture the output. Report to the user:
- Number of entities indexed
- Number of vault notes scanned
- Number of claude-mem observations contributing
- Size of the resulting index file

### Step 2: Cluster proposals

Read the new entity index. For each entity with `mention_count >= 10` and `memory_refs.length >= 5`:
1. Check if a cluster note exists at `{vault}/00 - Clusters/Cluster - {Entity Name}.md`
2. If yes, read the current version and compare with the current state from the index
3. If no, propose a new cluster note
4. Build a cluster note draft (see `reference/referral-system.md` for the template)

Present to the user **as a batch**:

```
📊 Cluster proposals:

New clusters (3):
  1. Customer Retention (23 observations, 11 notes)
  2. Project Alpha (14 observations, 8 notes)
  3. Team Hiring (11 observations, 5 notes)

Updated clusters (1):
  4. Product Roadmap (was: 18 obs, now: 22 obs — 4 new notes added)

Approve all? (yes / approve 1,3 / review 2 / scrap)
```

For each approved cluster:
- If it exists, move the current version to `{vault}/00 - Clusters/.archive/Cluster - {Name} - {today}.md`
- Write the new version to `{vault}/00 - Clusters/Cluster - {Entity Name}.md`

Skip step 2 entirely if `--index-only` or `--profile-only` is passed.

### Step 3: About Brian update

Query claude-mem for observations about Brian's working style, preferences, constraints, active projects, and people. Use `mcp__plugin_claude-mem_mcp-search__search` with query terms like:
- "Brian prefers", "Brian always", "Brian never"
- "Brian is working on"
- "Brian's rule"

Filter to facts meeting the **3+ confirmation rule**:
- Mentioned in 3+ observations
- Across 2+ distinct sessions
- With consistent phrasing or clear paraphrase

Read the current `{vault}/About Brian.md`. For any section written by `obsidian-bridge-auto`:
- Compute a diff between current and proposed
- Preserve any subsection written manually (check `source:` frontmatter within subsections if present, or trust any free-form prose Brian has added)

Present to the user:

```
📝 Proposed updates to About Brian.md:

Working style:
  + Voice-first via Whisper AI (confirmed 8 times across 5 sessions)
  - "Likes morning standups" (dropped — only 1 mention in 90 days)

Current projects (active):
  + [[Project Alpha]] — stateless auth design (12 mentions, 6 sessions)
  + [[Project Beta]] — churn analysis pipeline (7 mentions, 4 sessions)

People:
  + [[Sarah]] — Customer Success (9 mentions, 4 sessions)
  + [[Marcus]] — Analytics (6 mentions, 3 sessions)

Constraints:
  (no changes)

Approve all? (yes / review each / scrap)
```

On approval:
- Read current `About Brian.md`
- Update only the sections with `source: obsidian-bridge-auto` or that have not been manually edited
- Preserve manually-edited sections untouched
- Update `updated:` and `source-observations:` in frontmatter
- Write the new version

Skip step 3 entirely if `--index-only` is passed.

## Output summary

After all steps, print a summary:

```
✅ Memory rebuild complete

Entity index: 47 entities, rebuilt at 2026-04-22T15:30
Clusters: 3 created, 1 updated, 0 archived
About Brian: 4 additions, 1 removal

Next rebuild recommended: weekly (add cron job if not set up)
```

## Safety rules

- Never write to cluster notes or About Brian without explicit approval in this session
- Never modify user-owned notes in the vault
- Never overwrite a cluster note without first archiving the current version
- Never update sections of About Brian that appear to be manually written
- If the entity index rebuild fails, do NOT proceed to steps 2 or 3

## Error handling

- If obsidian-bridge config is missing: report and exit
- If claude-mem is not installed: report and exit (obsidian-bridge requires claude-mem)
- If the vault path in config doesn't exist: report and exit
- If the entity index script fails: report the error verbatim, do not proceed

## Frequency guidance

- **First run**: expect all three steps to propose significant changes
- **Weekly rebuild**: expect small incremental updates
- **After a heavy session**: run `/memory-rebuild --index-only` to capture new entities before the next conversation
