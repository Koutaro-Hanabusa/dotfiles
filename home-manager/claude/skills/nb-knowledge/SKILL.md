---
name: nb-knowledge
description: >
  Record non-trivial insights to nb notebooks in the background IMMEDIATELY after generating them:
  bug root causes, non-obvious API or framework behaviors, architectural tradeoffs, design decisions,
  counter-intuitive learnings, or corrected misconceptions. Fire during or right after the response
  that contains the insight — NOT in a later reflection step. Skip: trivial lookups (current time,
  version numbers), restated facts already in docs, boilerplate confirmations, and responses that
  merely summarize known information without new findings. Always uses the Write tool with a
  descriptive kebab-case filename, then commits via direct git commands. Never use `nb add` (it
  produces timestamp-only filenames and has been observed to hang).
---

> **[Skill Log]** このスキルが発動したら、最初に以下のBashコマンドを `run_in_background: true` で実行せよ:
> ```
> echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","tool_name":"Skill","skill":"nb-knowledge"}' >> ~/.config/claude-otel-monitoring/logs/claude-hooks.log
> ```

This skill manages automatic knowledge recording to nb notebooks throughout every session.

## Recording Rules

- **Always use the Write tool** to create notes. Do NOT use `nb add`.
- Reasons: `nb add` auto-generates timestamp-only filenames (e.g., `20260429153423.md`) which destroy discoverability, AND `nb add` has been observed to hang leaving zombie processes.
- Sync to remote via direct git commands (`git add` + `git commit` + `git push`), not via `nb sync`.
- No user confirmation is needed for note creation — always record automatically.
- `git push` may be blocked by the harness's permission gate; if so, ask the user to push manually.

## What to Record

- Q&A exchanges (questions asked and answers provided)
- Code review learnings (e.g., validation rules, framework behaviors)
- Design pattern discoveries (e.g., architectural decisions, state management approaches)
- Bug fixes and their root causes
- Any insights gained during the session

## How to Record

### 1. Detect work PC vs personal PC
- Work PC: `~/.is_work_pc` exists → notebook is `work`, path is `~/.nb/work/knowledge/`
- Personal PC: notebook is `home`, path is `~/.nb/home/knowledge/`

### 2. Choose a descriptive filename (kebab-case)

The filename must reflect the content. Search/recall depends on it.

Good examples:
- `tanstack-router-philosophy.md`
- `oauth-pkce-flow-pitfall.md`
- `react-suspense-fallback-quirk.md`
- `postgres-jsonb-index-tradeoffs.md`

Bad examples:
- `20260429153423.md` (timestamp only — `nb add` does this)
- `notes.md`, `learning.md` (too generic)
- `tanstack.md` (too broad)

### 3. Create the note via Write tool

```
# Personal PC
Write tool → /Users/<user>/.nb/home/knowledge/<kebab-case-title>.md

# Work PC
Write tool → /Users/<user>/.nb/work/knowledge/<kebab-case-title>.md
```

Use the Note Format below for the content.

### 4. Commit and push via direct git

```bash
cd ~/.nb/<notebook> && \
  git add knowledge/<kebab-case-title>.md && \
  git commit -m "Add <topic-summary>" && \
  git push
```

If `git push` is blocked by permission gate, tell the user:
> push できなかった。手動で `! cd ~/.nb/<notebook> && git push` してくれ

### 5. Updating existing notes

- Use the Edit tool directly on the file (not `nb edit` — it opens nvim and hangs).
- Then sync with the same git commands as step 4.

## Note Format

```markdown
# <Topic Title>

## Date: YYYY-MM-DD

## <Section 1>
- Key point
- Code example if relevant

## <Section 2>
...
```

## Important

- **Write tool is mandatory; `nb add` is forbidden.** Direct file write is reliable; `nb add` hangs.
- **Filename = discoverability.** Generic / timestamp filenames are unsearchable later.
- Group related learnings into a single note rather than many tiny files.
- Verify the file actually exists after Write (do not trust without confirming).
- The remote sync (push) is a separate concern from creation. Creation can succeed locally even if push fails.
