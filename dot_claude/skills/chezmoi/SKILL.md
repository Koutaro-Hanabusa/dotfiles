---
name: chezmoi
description: >
  Automated dotfiles sync with chezmoi. Triggers AFTER any file edit in the dotfiles/chezmoi
  source directory (paths containing `.local/share/chezmoi`, `sen/dotfiles`, or chezmoi naming
  patterns like `dot_`, `private_`, `executable_`). Automatically runs chezmoi apply and pushes
  changes to GitHub. Also triggers when user mentions chezmoi or dotfiles management.
---

> **[Skill Log]** このスキルが発動したら、最初に以下のBashコマンドを `run_in_background: true` で実行せよ:
> ```
> echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","tool_name":"Skill","skill":"chezmoi"}' >> ~/.config/claude-otel-monitoring/logs/claude-hooks.log
> ```

# chezmoi Dotfiles Auto-Sync

## Post-Edit Workflow (ALWAYS execute after editing dotfiles)

After ANY file edit in the chezmoi source directory, automatically run:

```bash
# 1. Apply changes to home directory
chezmoi apply

# 2. Commit and push to GitHub
cd ~/.local/share/chezmoi && git add -A && git commit -m "<concise description of changes>" && git push
```

Do NOT ask for confirmation — just do it. The user expects this to happen automatically.

## Commit Message

Write a concise commit message in Japanese describing what was changed. Examples:
- `zshrcにエイリアス追加`
- `nvimのLSP設定を修正`
- `tmuxのキーバインド変更`

## Naming Conventions

Use chezmoi naming when creating/editing source files:
- `dot_` → `.` (e.g. `dot_zshrc` → `~/.zshrc`)
- `private_` → permissions 0600 (e.g. `private_dot_tmux.conf`)
- `executable_` → +x bit
- `.tmpl` suffix → Go template processing

For details: [references/naming.md](references/naming.md)

## Template Syntax

For `.tmpl` files, use Go template syntax:
- `{{ .chezmoi.os }}` — OS detection (`darwin`, `linux`)
- `{{ .chezmoi.homeDir }}` — home directory path
- `{{ if stat (joinPath .chezmoi.homeDir ".is_work_pc") }}` — file existence check

For details: [references/templates.md](references/templates.md)

## Command Reference

For details: [references/commands.md](references/commands.md)
