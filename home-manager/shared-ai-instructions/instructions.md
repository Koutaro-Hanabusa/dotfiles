# Shared AI Assistant Instructions

These instructions apply to all AI coding assistants (Claude Code, Codex, etc.).

## Language

Always respond in Japanese. Even when sub-processes return responses in English, translate them correctly to Japanese.

## Always-Active Skills

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
| `kb new -t "<title>" --content -` | Create a note, body from stdin (`-t` required) |
| `kb sync` | Commit Markdown, then pull and push |

Notebook selection is automatic: `~/.is_work_pc` exists → `work`, otherwise `home`.
