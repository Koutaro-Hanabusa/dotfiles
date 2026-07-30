# Shared AI Assistant Instructions

These instructions apply to all AI coding assistants (Claude Code, Codex, etc.).

## Language

Always respond in Japanese. Even when sub-processes return responses in English, translate them correctly to Japanese.

## Always-Active Skills

### nb-knowledge (Knowledge Recording) — Required Every Session

- When Q&A, learnings, bug fixes, or design decisions occur during a session, record them via `kb` in the background.
- At task completion and before session end, always review for missed recordings.
- Write the note in one command (never block the main conversation):
  ```bash
  kb new -t "<descriptive title>" --folder knowledge --content - <<'EOF'
  <body>
  EOF
  ```
- `kb` picks the notebook from the machine — `work` when `~/.is_work_pc` exists, `home` otherwise. Do not pass `--notebook` unless deliberately overriding.
- Sync with `kb sync`. It stages Markdown only, commits, then pulls and pushes.
- To update existing notes: find with `kb search <term> -l`, edit the file directly, then `kb sync`. There is no `kb edit`.
- NEVER use `nb` — it is retired (27,000 lines of bash, 18.5s per search; `nb add` produced timestamp-only filenames and hung).

### development-principles (Dev Principles) — Apply to All Decisions

- Follow development principles when writing, designing, reviewing, or proposing code.
- Consciously apply these principles in the following situations:
  - **Design decisions**: Simplicity > extensibility. Respect YAGNI.
  - **On errors**: Don't brute-force through. Investigate root causes.
  - **Before implementation**: Read existing code first (Genchi Genbutsu). Never write without reading.
  - **On completion**: Ask yourself if you verified it works (Inspection).

## Documentation with kb

`kb` is the knowledge CLI (self-authored, Rust). Notes live in `~/.kb/{home,work}/knowledge/`
as plain Markdown with YAML frontmatter, and each notebook is a git repository that syncs to
Cloudflare AI Search.

| Command | Purpose |
| --- | --- |
| `kb search <pattern>` | Full-text search across both notebooks (regex, smart case) |
| `kb ls --since 7d` | Recently touched notes |
| `kb new <title> --content -` | Create a note, body from stdin |
| `kb sync` | Commit Markdown, then pull and push |

Notebook selection is automatic: `~/.is_work_pc` exists → `work`, otherwise `home`.
