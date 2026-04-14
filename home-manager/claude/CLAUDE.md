you must: Always respond in Japanese. Even when sub-agents return responses in English, translate them correctly to Japanese.
you must: Always use the time MCP server when retrieving dates.
you must: When receiving instructions or questions from the user, always delegate tasks to the appropriate sub-agents from the following list:

- @.react-pro
- @.frontend-developer
- @.golang-pro
- @.qa-expert
- @.backend-developer
- @.laravel-pro

you must: When implementing designs or using the Figma DevMode MCP, refer to ../skills/frontend-design/SKILL.md for implementation.
you must: After editing ANY file in this dotfiles repository, ALWAYS automatically commit + push to GitHub without asking. If a `.nix` file was changed, run `home-manager switch --flake ~/dotfiles` before committing. This is non-negotiable — never wait for the user to say "apply" or "push". Just do it immediately after every edit.
you must: When a skill should be triggered (based on its trigger conditions in the skill description), ALWAYS invoke it via the `Skill` tool. NEVER read the skill content directly or act on it without going through the Skill tool. This is required for hook-based logging to work correctly. The PreToolUse hook only fires when the Skill tool is explicitly called.
you must: When presenting output that originated from Codex (rescue, review, adversarial-review, stop-gate, or any Codex job result), wrap the ENTIRE content in a blockquote with a decorated header line. Format:

> **from codex** | `{kindLabel}` | {status_emoji} {status}
>
> （Codex の出力内容をすべてこの blockquote 内に入れる）

Status emoji mapping: completed=✅, running=⏳, failed=❌, cancelled=🚫
kindLabel examples: rescue, review, adversarial-review, stop-gate

## Shared Instructions (synced from shared-ai-instructions/instructions.md)

### Always-Active Skills

#### nb-knowledge (Knowledge Recording) — Required Every Session
- When Q&A, learnings, bug fixes, or design decisions occur during a session, record them via `nb add` in the background.
- At task completion and before session end, always review for missed recordings.
- Run `nb add home:knowledge/ -c "content"` with `run_in_background: true` (never block the main conversation).
- For work PCs: use `nb add work:knowledge/ -c "content"` instead.
- To update existing notes: use the Edit tool directly, then `nb sync`. NEVER use `nb edit` — it opens nvim and hangs in non-interactive environments.

#### development-principles (Dev Principles) — Apply to All Decisions
- Follow the development-principles skill guidelines when writing, designing, reviewing, or proposing code.
- Consciously apply these principles in the following situations:
  - **Design decisions**: Simplicity > extensibility. Respect YAGNI.
  - **On errors**: Don't brute-force through. Investigate root causes.
  - **Before implementation**: Read existing code first (Genchi Genbutsu). Never write without reading.
  - **On completion**: Ask yourself if you verified it works (Inspection).

### Documentation with nb

Follow the nb-knowledge skill (see "Always-Active Skills" above) to record learnings.
Work PC detection: `~/.is_work_pc` exists → `work:knowledge/`, otherwise `home:knowledge/`.
