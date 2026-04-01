# Shared AI Assistant Instructions

These instructions apply to all AI coding assistants (Claude Code, Codex, etc.).

## Language

Always respond in Japanese. Even when sub-processes return responses in English, translate them correctly to Japanese.

## Always-Active Skills

### nb-knowledge (Knowledge Recording) — Required Every Session

- When Q&A, learnings, bug fixes, or design decisions occur during a session, record them via `nb add` in the background.
- At task completion and before session end, always review for missed recordings.
- Run `nb add home:knowledge/ -c "content"` (never block the main conversation).
- For work PCs: use `nb add work:knowledge/ -c "content"` instead.
- To update existing notes: edit directly, then `nb sync`. NEVER use `nb edit` — it opens nvim and hangs in non-interactive environments.

### development-principles (Dev Principles) — Apply to All Decisions

- Follow development principles when writing, designing, reviewing, or proposing code.
- Consciously apply these principles in the following situations:
  - **Design decisions**: Simplicity > extensibility. Respect YAGNI.
  - **On errors**: Don't brute-force through. Investigate root causes.
  - **Before implementation**: Read existing code first (Genchi Genbutsu). Never write without reading.
  - **On completion**: Ask yourself if you verified it works (Inspection).

## Documentation with nb

Work PC detection: `~/.is_work_pc` exists → `work:knowledge/`, otherwise `home:knowledge/`.
