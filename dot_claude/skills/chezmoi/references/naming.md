# chezmoi File Naming Conventions

## Prefix → Target Mapping

| Prefix | Effect | Example Source → Target |
|--------|--------|------------------------|
| `dot_` | Replace with `.` | `dot_zshrc` → `.zshrc` |
| `private_` | Set permissions to 0600 | `private_dot_ssh/config` → `.ssh/config` (0600) |
| `executable_` | Set executable bit | `executable_script.sh` → `script.sh` (+x) |
| `readonly_` | Set permissions to 0444 | `readonly_config` → `config` (0444) |
| `empty_` | Ensure file exists (even if empty) | `empty_dot_gitconfig` → `.gitconfig` |
| `create_` | Create only if target doesn't exist | `create_dot_bashrc` → `.bashrc` (no overwrite) |
| `modify_` | Modify existing target | `modify_dot_bashrc` → runs script to modify `.bashrc` |
| `remove_` | Remove target file | `remove_dot_old_config` → removes `.old_config` |
| `symlink_` | Create symlink | `symlink_dot_config` → `.config` (symlink) |
| `run_` | Run script (not a managed file) | `run_install.sh` → executes script |
| `literal_` | Use filename literally (no prefix processing) | `literal_dot_file` → `dot_file` |

## Suffix Conventions

| Suffix | Effect |
|--------|--------|
| `.tmpl` | Process as Go template before applying |
| `.literal` | Use filename literally |

## Prefix Combinations

Prefixes can be combined. Order matters — use this order:

```
[type_][target_][modifier_]name[.tmpl]
```

Common combinations:
- `private_dot_` → Hidden file with 0600 permissions
- `executable_dot_` → Hidden executable file
- `run_once_` → Script that runs only once per machine
- `run_once_before_` → One-time script before apply
- `run_onchange_` → Script that re-runs when its content changes
- `run_onchange_after_` → Re-run script after apply

## Directory Prefixes

| Prefix | Effect |
|--------|--------|
| `dot_` | Replace with `.` |
| `private_` | Set directory permissions to 0700 |
| `exact_` | Remove files in target not in source |
| `readonly_` | Set directory permissions to 0555 |
| `external_` | Managed externally (see `.chezmoiexternal`) |

## Script Ordering

Scripts with `run_` prefix execute in alphabetical order. Use numeric prefixes for ordering:

```
run_once_before_01-install-packages.sh
run_once_before_02-setup-config.sh
run_after_99-cleanup.sh
```

## Special Files

| File | Purpose |
|------|---------|
| `.chezmoiignore` | Files/patterns to exclude from management |
| `.chezmoiremove` | Files to remove from target |
| `.chezmoiroot` | Change the target root directory |
| `.chezmoiversion` | Minimum chezmoi version requirement |
| `.chezmoiexternal.$FORMAT` | External file/archive sources |
| `.chezmoidata.$FORMAT` | Template data (json/toml/yaml) |
| `.chezmoi.$FORMAT.tmpl` | Config template for `chezmoi init` |

## Examples

```
# Source directory structure
dot_config/
  nvim/
    init.lua                    → ~/.config/nvim/init.lua
  private_karabiner/
    karabiner.json              → ~/.config/karabiner/karabiner.json (0700 dir)
  ghostty/
    config                      → ~/.config/ghostty/config
dot_zshrc                       → ~/.zshrc
private_dot_tmux.conf           → ~/.tmux.conf (0600)
dot_textlintrc.json.tmpl        → ~/.textlintrc.json (template-processed)
executable_setup.sh             → ~/setup.sh (+x)
run_once_install-packages.sh    → (executed once, not installed)
```
