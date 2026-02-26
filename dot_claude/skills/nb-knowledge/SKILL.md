---
name: nb-knowledge
description: Automatically record Q&A exchanges, code review learnings, design pattern discoveries, and session insights to nb notebooks in the background. Always active — no user invocation needed.
---

This skill manages automatic knowledge recording to nb notebooks throughout every session.

## Recording Rules

- All nb recording MUST be run in the background (`run_in_background: true` in Bash). Never block the main conversation flow.
- No user confirmation is needed for nb writes — always record automatically.

## What to Record

- Q&A exchanges (questions asked and answers provided)
- Code review learnings (e.g., validation rules, framework behaviors)
- Design pattern discoveries (e.g., architectural decisions, state management approaches)
- Bug fixes and their root causes
- Any insights gained during the session

## How to Record

1. Detect work PC vs personal PC:
   - Work PC: `~/.is_work_pc` exists → use `work:knowledge/`
   - Personal PC: use `home:knowledge/`

2. Create new notes:

```bash
# Work PC
nb add work:knowledge/ -c "content"

# Personal PC
nb add home:knowledge/ -c "content"
```

3. To update existing notes, directly edit the file with the Edit tool, then run `nb sync` to push changes:
   - Home: `~/.nb/home/knowledge/<filename>`
   - Work: `~/.nb/work/knowledge/<filename>`
   - NEVER use `nb edit` — it opens nvim and hangs in non-interactive environments.

4. When running `nb sync`, ensure the active notebook has a remote configured.
   The `work` notebook may not have a remote. Switch to the correct notebook first:

```bash
nb use home && nb sync
# or
nb use work && nb sync
```

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

- Always run in the background — the user should never wait for nb operations.
- Group related learnings into a single note rather than creating many small files.
- Use descriptive topic titles for easy retrieval later.
