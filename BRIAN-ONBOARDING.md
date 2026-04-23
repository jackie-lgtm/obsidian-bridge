# Welcome, Brian — Your New Memory System

Hi Brian. Jackie set up a memory system for your Claude Code that's designed to work the way **you** actually think and work — voice-first, lots of ideas flying around, needs to keep up without getting in the way.

This document is just for you. It explains what the system does, how to use it, and what to do when it feels off.

---

## The big idea, in one paragraph

You talk. Claude listens. Your words get turned into short, findable notes in your Obsidian vault ("Bryan Brain"). When you mention a person, project, or topic you've talked about before, Claude quietly reminds you what you said last time — without interrupting. Once a week, Claude builds a map of how your ideas connect, so you can *see* your own thinking.

That's it. Everything else is just details.

---

## What you need to install (one time)

Open Claude Code on your Mac. Type these **six commands**, one at a time. Press Enter after each. Wait for each to finish before typing the next.

**1. Install the memory engine (required first):**
```
/plugin marketplace add thedotmack/claude-mem
```

**2.**
```
/plugin install claude-mem
```

**3. Install the Obsidian bridge (this is the main thing):**
```
/plugin marketplace add https://github.com/jackie-lgtm/obsidian-bridge
```

**4.**
```
/plugin install obsidian-bridge
```

**5. Install the health-check tool:**
```
/plugin marketplace add https://github.com/jackie-lgtm/memory-audit
```

**6.**
```
/plugin install memory-audit
```

Then **close and reopen Claude Code**. That's it for install.

---

## First time you use it

The first time you say "save this to Obsidian" during a conversation, Claude will ask you two things:

1. **"What's the name of your Obsidian vault?"**
   → Answer: `Bryan Brain`

2. **"What's the full path to your vault on this Mac?"**
   → If you're not sure: open Obsidian, right-click "Bryan Brain" in the vault switcher, click "Copy vault path." Paste that into Claude.

Claude saves your answers. You won't have to answer again.

---

## How to use it (day-to-day)

### Talking normally

Just talk to Claude like you always do. Use voice, use typing — it doesn't matter. The system is listening in the background but **it stays out of your way**.

You'll only see it when one of three things happens:

### Thing 1: Claude gently reminds you about past context

When you mention something you've talked about before (a person's name, a project, a topic), Claude might add one line at the end of its answer like:

> ↪ *You mentioned **Project Alpha** — last context: decision on pricing, Apr 18. Pull it up?*

**What to do:**
- Want to see the past context? Say "yes" or "pull it up"
- Don't care? Ignore it completely and keep going. No harm done.

### Thing 2: Claude offers to save your ideas

When you've been talking through an idea and reach a natural stopping point, Claude might say:

> 📝 Captured 4 atomic notes from the last 3 minutes — thread `t7a2`. Write to Inbox?
> 1. Churn spike hypothesis: onboarding friction
> 2. Specific friction: SSO config at step 3
> 3. Proposed fix: skip SSO for trials
> 4. Related: your Apr 18 pricing decision

**What to do:**
- All look good? Say **"yes"** or **"save them"**
- Only want a few? Say **"keep 1, 3"** (just the numbers you want)
- None of them? Say **"scrap"** or **"no"**

**This is the key thing:** Claude doesn't save anything automatically. You always approve.

### Thing 3: You ask Claude to save something

Any time you say any of these, Claude will draft a note:
- "Save this"
- "Log this"
- "Capture this"
- "Add this to my notes"
- "Put this in my vault"

Then same as Thing 2 — Claude shows you the draft, you approve or reject.

---

## Where your notes go

Everything Claude saves goes into **one folder**: `Bryan Brain/99 - Inbox/`

Think of it like an actual inbox — stuff comes in, you review it when you have time, then you move it to the right place (or delete it).

**Your Inbox triage routine (whenever you want, maybe once a week):**

1. Open Obsidian
2. Click the `99 - Inbox` folder
3. Sort by filename (that puts newest at the top)
4. Read each note — they're short, 3–5 lines each
5. For each note, decide:
   - **Keep it?** Drag it to the folder where it belongs (Projects, People, etc.)
   - **Combine it with another note?** Copy the content, paste it into the existing note, delete the inbox one
   - **Don't need it?** Delete it
6. In the note's frontmatter at the top, change `status: inbox` to `status: triaged` on the ones you keep

That's it. No system, no stress. Just read, decide, file.

---

## Special folders Claude manages (don't touch these)

Claude takes care of these automatically — **do not edit them by hand** because Claude will overwrite them:

- **`Bryan Brain/About Brian.md`** — a one-page summary of what Claude knows about you (your working style, active projects, people, preferences). Updates once a week. Only adds things you've mentioned 3+ times.

- **`Bryan Brain/00 - Clusters/`** — auto-generated "thought map" notes. Each one shows how a cluster of your ideas connects together. Also updates weekly.

Everything **else** in the vault is yours to organize however you want.

---

## Important commands to remember

There are only three commands you need to know. Type them in Claude Code with the slash:

### `/memory-audit`
Runs a health check. Tells you if everything is working, if anything is broken, and what to do about it. Safe to run anytime — it doesn't change anything.

### `/memory-rebuild`
Refreshes the memory system. Rebuilds the list of who/what you've been talking about, updates your cluster notes, updates your "About Brian" note. Claude will show you any changes and ask before writing them.

**Run this weekly** or when the system feels stale. Takes about a minute.

### `/memory-rebuild --index-only`
Quick version — only refreshes the "who/what you talked about" list. Use this after a long conversation if you want Claude to remember new names or topics immediately.

---

## If something feels wrong

### "Claude keeps interrupting me"
The system is supposed to stay quiet. If it's being too noisy:
- Tell Claude: "stop surfacing connections for this conversation"
- Or edit `~/.claude/obsidian-bridge.config.json` and change `"surfacing_mode": "inline"` to `"surfacing_mode": "off"`

### "Claude saved something I didn't want saved"
Check your `99 - Inbox/` folder in Obsidian. Delete the file. Nothing is permanent until you triage it.

### "Claude isn't remembering anything"
Run `/memory-audit`. It'll tell you what's wrong. Most likely: you need to restart Claude Code, or the entity index needs rebuilding (run `/memory-rebuild`).

### "I want to see what Claude knows about me"
Open `Bryan Brain/About Brian.md`. That's the summary. If something's wrong or outdated, just **edit it manually** — Claude respects your hand-edits and won't overwrite them.

### "I want to delete everything and start over"
- Delete all files in `Bryan Brain/99 - Inbox/`
- Delete `Bryan Brain/About Brian.md`
- Delete all files in `Bryan Brain/00 - Clusters/`
- Delete `~/.claude/obsidian-bridge.entities.json`
- Delete `~/.claude/obsidian-bridge.config.json`
- Next time you use Claude, it'll reconfigure from scratch

Nothing you do to the vault can break Claude. It'll rebuild.

---

## What Claude will NEVER do

Jackie built this with strict rules. Claude will never:

- ❌ Save anything without showing you first and getting your "yes"
- ❌ Edit notes you wrote by hand
- ❌ Look at any vault other than Bryan Brain
- ❌ Send your notes anywhere outside your Mac
- ❌ Reorganize your existing notes
- ❌ Auto-post, auto-email, or auto-send anything
- ❌ Update "About Brian" based on something you said only once
- ❌ Make up connections you didn't actually mention

---

## One-page cheat sheet

| I want to... | Say or do |
|---|---|
| Save an idea to Obsidian | "Save this" / "capture this" |
| See past context on something | Ask "what did I say about X?" |
| Approve Claude's draft notes | "yes" or "save them" |
| Only keep some drafts | "keep 1, 3" (etc.) |
| Reject all drafts | "no" or "scrap" |
| Check if system is healthy | `/memory-audit` |
| Refresh the memory system | `/memory-rebuild` |
| Stop Claude surfacing connections | "stop surfacing for this conversation" |
| Review new notes | Open Obsidian → `99 - Inbox/` |

---

## The philosophy, in plain words

Your brain is fast and associative. Most note-taking systems slow you down because they make you organize things in the moment. This system does the opposite: **you just talk, it captures, you organize later when you feel like it.**

The notes are **short on purpose**. If a note is longer than a paragraph, it's wrong and Claude is supposed to split it into smaller ones. Short notes are easy to read, easy to find, and easy to link together.

The **clusters** are the magic trick. Once a week, Claude shows you which ideas keep coming up together. Most of the time, you'll say "huh, I didn't realize I'd been thinking about that so much." That's the system working.

---

## Questions for Jackie

If something's confusing or broken, just text Jackie. She built all of this with specific knowledge of how you work — she's the best person to fix it or adjust it.

Welcome to having a memory system that actually fits your brain.

— Jackie (via Claude)
