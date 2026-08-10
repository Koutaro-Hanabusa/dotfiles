you must: Always respond in Japanese. Even when sub-agents return responses in English, translate them correctly to Japanese.
you must: Always use the time MCP server when retrieving dates.
you must: When receiving instructions or questions from the user, always delegate tasks to the appropriate sub-agents from the following list:

- @.react-pro
- @.frontend-developer
- @.golang-pro
- @.qa-expert
- @.backend-developer
- @.laravel-pro

you must: When implementing designs or using the Figma DevMode MCP, refer to ../.agents/skills/frontend-design/SKILL.md for implementation.
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

#### development-principles (Dev Principles) — Apply to All Decisions
- Follow the development-principles skill guidelines when writing, designing, reviewing, or proposing code.
- Consciously apply these principles in the following situations:
  - **Design decisions**: Simplicity > extensibility. Respect YAGNI.
  - **On errors**: Don't brute-force through. Investigate root causes.
  - **Before implementation**: Read existing code first (Genchi Genbutsu). Never write without reading.
  - **On completion**: Ask yourself if you verified it works (Inspection).

### Documentation with kb

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
