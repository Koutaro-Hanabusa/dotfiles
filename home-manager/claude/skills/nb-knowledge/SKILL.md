---
name: nb-knowledge
description: >
  Record non-trivial insights to the knowledge base in the background IMMEDIATELY after
  generating them: bug root causes, non-obvious API or framework behaviors, architectural tradeoffs,
  design decisions, counter-intuitive learnings, or corrected misconceptions. Fire during or right after
  the response that contains the insight — NOT in a later reflection step. Skip: trivial lookups (current
  time, version numbers), restated facts already in docs, boilerplate confirmations, and responses that
  merely summarize known information without new findings. Always uses `kb new` with a descriptive
  title, then `kb sync`. Never use `nb` (it is retired: 27,000 lines of bash, 18.5s per search, and
  `nb add` produced timestamp-only filenames and hung).
---

This skill manages automatic knowledge recording to the knowledge base throughout every session.

## Recording Rules

- **Always use `kb new`** to create notes. It generates the frontmatter and picks the notebook, so
  there is nothing to hand-write and nothing to get wrong.
- `kb` selects the notebook from the machine — `work` when `~/.is_work_pc` exists, `home` otherwise.
  Do not pass `--notebook` unless you are deliberately overriding that.
- Sync with `kb sync`. It stages Markdown only, commits with a generated message, then pulls and pushes.
- No user confirmation is needed for note creation — always record automatically.
- Run recording in the background (`run_in_background: true`) so it never blocks the conversation.
- `kb sync` may fail to push if the harness blocks network access; if so, tell the user to run
  `! kb sync` themselves.

## What to Record

- Q&A exchanges (questions asked and answers provided)
- Code review learnings (e.g., validation rules, framework behaviors)
- Design pattern discoveries (e.g., architectural decisions, state management approaches)
- Bug fixes and their root causes
- Any insights gained during the session

## How to Record

### 1. Choose a descriptive title

The title becomes both the frontmatter `title` and the filename, so search depends on it.

Good: `TanStack Router の routes を薄く保つ方針`, `OAuth PKCE flow の落とし穴`,
`postgres jsonb index のトレードオフ`

Bad: `メモ`, `学び`, `tanstack`（broad）, `20260429153423`（what the retired `nb add` produced）

### 2. Write the note in one command

```bash
kb new -t "<descriptive title>" --folder knowledge --content - <<'EOF'
## Date: YYYY-MM-DD

## <Section 1>
- Key point
- Code example if relevant

## <Section 2>
...
EOF
```

`kb new` prints the path it wrote. It never overwrites: a colliding title gets a `-2` suffix.

`--folder` is where the note goes; `--tags a,b` overrides the tags, which otherwise
comes from the folder name.

### 3. Sync

```bash
kb sync
```

### 4. Updating an existing note

Find it, then edit it directly — there is no `kb edit`:

```bash
kb search "<term>" -l      # paths of matching notes
kb ls --since 7d           # recently touched notes
```

Use the Edit tool on the path, then `kb sync`.

## Note Format

`kb new` writes the frontmatter; supply only the body:

```markdown
## Date: YYYY-MM-DD

## <Section 1>
- Key point

## <Section 2>
...
```

The resulting file looks like:

```markdown
---
title: <the title you passed>
tags: [knowledge]
created: 2026-07-29T12:14:54+09:00
updated: 2026-07-29T12:14:54+09:00
---

## Date: ...
```

## Important

- **`kb new` is mandatory; `nb` is retired.** Do not hand-write frontmatter and do not use raw
  `git add`/`commit` — `kb sync` exists so that unrelated staged files never get swept into a note commit.
- **Title = discoverability.** Generic or timestamp titles are unsearchable later.
- Group related learnings into a single note rather than many tiny files.
- Creation and push are separate concerns: a note can be written locally even when push fails.
