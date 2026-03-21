# chezmoi Command Reference

## Setup

```bash
# Install
brew install chezmoi            # macOS
sh -c "$(curl -fsLS get.chezmoi.io)"  # any OS

# Initialize from GitHub repo
chezmoi init $GITHUB_USERNAME
chezmoi init --apply $GITHUB_USERNAME  # init + apply in one step

# Initialize from any git repo
chezmoi init https://github.com/user/dotfiles.git
```

## Daily Operations

### View state
```bash
chezmoi status                  # Show changed files (A=add, M=modify, D=delete)
chezmoi diff                    # Show full diff of pending changes
chezmoi diff ~/.zshrc           # Diff a specific file
chezmoi managed                 # List all managed files
chezmoi managed --include=files # List managed files only (no dirs)
chezmoi unmanaged               # List unmanaged files in home
chezmoi data                    # Show template data
chezmoi cat ~/.zshrc            # Show what file would look like after apply
chezmoi source-path ~/.zshrc    # Show source path for a target
chezmoi target-path dot_zshrc   # Show target path for a source
```

### Make changes
```bash
chezmoi add ~/.zshrc            # Add file to management
chezmoi add --encrypt ~/.ssh/id_rsa  # Add with encryption
chezmoi add --template ~/.zshrc # Add as template
chezmoi add --autotemplate ~/.gitconfig  # Auto-detect template values
chezmoi re-add                  # Re-add all modified managed files

chezmoi edit ~/.zshrc           # Edit source file (opens $EDITOR)
chezmoi edit --apply ~/.zshrc   # Edit and apply immediately
chezmoi edit-config             # Edit chezmoi config

chezmoi forget ~/.old_file      # Remove file from management
chezmoi destroy ~/.old_file     # Remove from management AND delete target

chezmoi chattr +private ~/.ssh/config     # Add private attribute
chezmoi chattr +executable ~/bin/script   # Add executable attribute
chezmoi chattr +template ~/.gitconfig     # Add template attribute
```

### Apply changes
```bash
chezmoi apply                   # Apply all changes
chezmoi apply ~/.zshrc          # Apply specific file
chezmoi apply -v                # Apply with verbose output
chezmoi apply -n -v             # Dry run (show what would change)
chezmoi apply --force           # Force apply, overwrite conflicts
```

### Sync with remote
```bash
chezmoi update                  # git pull + apply
chezmoi git pull                # Pull only (no apply)
chezmoi git -- status           # Run git commands in source dir
chezmoi cd                      # cd to source directory (opens subshell)
```

## Advanced Operations

### Externals
```bash
chezmoi apply -R                # Refresh externals during apply
chezmoi apply --refresh-externals  # Same as above
```

### Merge conflicts
```bash
chezmoi merge ~/.zshrc          # Three-way merge for conflicts
chezmoi merge-all               # Merge all conflicting files
```

### Diagnostics
```bash
chezmoi doctor                  # Check system and configuration
chezmoi verify                  # Verify target state matches source
chezmoi state dump              # Dump chezmoi state database
chezmoi state reset             # Reset chezmoi state
```

### Encryption
```bash
chezmoi age-keygen --output=$HOME/key.txt   # Generate age key
chezmoi decrypt <file>          # Decrypt a file
chezmoi encrypt <file>          # Encrypt a file
```

## Configuration File

Location: `~/.config/chezmoi/chezmoi.toml` (or .yaml/.json)

```toml
[edit]
command = "nvim"

[diff]
command = "delta"

[merge]
command = "nvim"
args = ["-d"]

[git]
autoCommit = false
autoPush = false

encryption = "age"
[age]
identity = "~/.config/chezmoi/key.txt"
recipient = "age1..."
```

## Common Flags

| Flag | Description |
|------|-------------|
| `-v, --verbose` | Show detailed output |
| `-n, --dry-run` | Show what would happen without making changes |
| `-R, --refresh-externals` | Refresh external sources |
| `--force` | Force operation, overwrite conflicts |
| `--exclude=TYPE` | Exclude entries by type (scripts, encrypted, etc.) |
| `--include=TYPE` | Include entries by type |
| `-k, --keep-going` | Continue on errors |
