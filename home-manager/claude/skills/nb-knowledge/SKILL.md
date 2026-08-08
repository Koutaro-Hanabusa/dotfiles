---
name: nb-knowledge
description: >
  Record non-trivial insights to the knowledge base in the background IMMEDIATELY after
  generating them: bug root causes, non-obvious API or framework behaviors, architectural tradeoffs,
  design decisions, counter-intuitive learnings, or corrected misconceptions. Fire during or right after
  the response that contains the insight — NOT in a later reflection step. Skip: trivial lookups (current
  time, version numbers), restated facts already in docs, boilerplate confirmations, and responses that
  merely summarize known information without new findings. Always uses `kb new -t "<title>"` (the `-t` is
  mandatory) with a body split into `##` sections, then `kb sync`. Never use `nb` (it is retired: 27,000
  lines of bash, 18.5s per search, and `nb add` produced timestamp-only filenames and hung).
---

This skill manages automatic knowledge recording to the knowledge base throughout every session.

## Recording Rules

- **Always use `kb new -t "<title>"`** to create notes. The `-t` is not optional — see below for what
  happens without it. kb generates the frontmatter and picks the notebook, so there is nothing to
  hand-write and nothing to get wrong.
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

### 1. Choose a descriptive title and pass it with `-t`

`-t` sets both the frontmatter `title` and the filename, so search depends on it.

**Passing the title as a positional argument does not work.** `kb new "<title>" --content -` treats the
positional as *content* — kb only reads it as a filename when it carries an extension. With no `-t`, kb
takes the title from the first line of the body and names the file after the clock (`20260729095853.md`),
and no `# heading` is written. The work notebook already holds 26 such notes from July 2026; they are
effectively unsearchable. This is the single most common way this skill gets broken.

Good: `TanStack Router の routes を薄く保つ方針`, `OAuth PKCE flow の落とし穴`,
`postgres jsonb index のトレードオフ`

Bad: `メモ`, `学び`, `tanstack`（broad）, `20260429153423`（what you get when `-t` is missing）

### 2. Write the note in one command

```bash
kb new -t "<descriptive title>" --folder knowledge --content - <<'EOF'
## <Section 1>

- Key point
- Code example if relevant

## <Section 2>

...
EOF
```

Body rules — this is the part that keeps getting skipped:

- **Do not write an `# H1`.** `kb new -t` already inserts `# <title>` above your body; a hand-written
  one duplicates it.
- **Do not write a `## Date:` line.** The frontmatter carries `created` / `updated` already, and a
  hand-written date drifts from them. Date the body only when the *content* is time-bound (a snapshot,
  a survey as of a given day) — and then say so in the section heading itself.
- **Two or more `##` sections, always.** One wall of prose is not a note; it is a paragraph you will
  never find again. Split it — `## 事象` / `## 原因` / `## 対応`, `## 結論` / `## 根拠`, or whatever
  fits the finding.
- Put commands, code, and file paths in fenced blocks so they survive search and copy-paste.

`--folder` is where the note goes; `--tags a,b` overrides the tags, which otherwise
comes from the folder name.

### 3. Check what kb actually wrote

`kb new` prints the path it wrote. Read it before moving on:

- The filename must be your title, not a bare timestamp. A timestamp means `-t` was dropped — remove
  the note with `kb delete <path>` and run the command again.
- kb never overwrites: a colliding title gets a `-2` suffix.

### 4. Sync

```bash
kb sync
```

### 5. Updating an existing note

Find it, then edit it directly — there is no `kb edit`:

```bash
kb search "<term>" -l      # paths of matching notes
kb ls --since 7d           # recently touched notes
```

Use the Edit tool on the path, then `kb sync`.

## Note Format

`kb new -t` writes the frontmatter *and* the `# <title>` heading; supply only the sections below it:

```markdown
## <Section 1>

- Key point

## <Section 2>

...
```

The resulting file looks like this — note the `# heading` you did not write:

```markdown
---
title: <the title you passed>
tags: [knowledge]
created: 2026-07-29T12:14:54+09:00
updated: 2026-07-29T12:14:54+09:00
---

# <the title you passed>

## <Section 1>

- Key point
```

## Important

- **`-t` is mandatory; `nb` is retired.** Do not hand-write frontmatter and do not use raw
  `git add`/`commit` — `kb sync` exists so that unrelated staged files never get swept into a note commit.
- **Title = discoverability.** Generic or timestamp titles are unsearchable later.
- **Sections = readability six months from now.** A single prose paragraph reads fine the day you write
  it and fails you afterwards.
- Group related learnings into a single note rather than many tiny files.
- Creation and push are separate concerns: a note can be written locally even when push fails.
