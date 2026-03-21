# chezmoi Template Syntax

## Basics

chezmoi uses Go's `text/template` with sprig functions.
Template files have `.tmpl` suffix.

```
{{ .chezmoi.os }}          → "darwin", "linux", "windows"
{{ .chezmoi.arch }}        → "amd64", "arm64"
{{ .chezmoi.hostname }}    → machine hostname
{{ .chezmoi.username }}    → current user
{{ .chezmoi.homeDir }}     → home directory path
{{ .chezmoi.sourceDir }}   → chezmoi source directory
{{ .chezmoi.kernel.osrelease }}  → kernel version (Linux)
```

## Whitespace Control

```
{{- .value }}    → trim left whitespace
{{ .value -}}    → trim right whitespace
{{- .value -}}   → trim both sides
```

## Conditionals

```
{{ if eq .chezmoi.os "darwin" -}}
# macOS specific
export HOMEBREW_PREFIX="/opt/homebrew"
{{ else if eq .chezmoi.os "linux" -}}
# Linux specific
export PATH="$HOME/.local/bin:$PATH"
{{ end -}}
```

### Boolean operators

```
{{ if and (eq .chezmoi.os "darwin") (eq .chezmoi.arch "arm64") -}}
# Apple Silicon Mac
{{ end -}}

{{ if or (eq .chezmoi.os "darwin") (eq .chezmoi.os "linux") -}}
# Unix-like
{{ end -}}

{{ if not (eq .chezmoi.os "windows") -}}
# Non-Windows
{{ end -}}
```

### File/directory existence check

```
{{ if stat (joinPath .chezmoi.homeDir ".is_work_pc") -}}
# Work PC configuration
{{ end -}}
```

## Custom Data

### .chezmoidata.yaml

```yaml
email: "user@example.com"
editor: "nvim"
is_work: false
git:
  name: "Your Name"
  email: "you@example.com"
```

### Usage in templates

```
[user]
  name = {{ .git.name }}
  email = {{ .git.email }}
```

## Interactive Prompts (.chezmoi.yaml.tmpl)

Generate chezmoi config via `chezmoi init`:

```yaml
{{ $email := promptStringOnce . "email" "Email address" -}}
{{ $isWork := promptBoolOnce . "is_work" "Is this a work machine" -}}

data:
  email: {{ $email | quote }}
  is_work: {{ $isWork }}
```

## Useful Functions

### String functions
```
{{ .value | upper }}         → uppercase
{{ .value | lower }}         → lowercase
{{ .value | title }}         → title case
{{ .value | quote }}         → wrap in quotes
{{ .value | trim }}          → trim whitespace
{{ .value | replace "a" "b" }}  → string replace
```

### Path functions
```
{{ joinPath .chezmoi.homeDir ".config" "nvim" }}
{{ includeTemplate "partial.tmpl" . }}
```

### Environment & commands
```
{{ env "EDITOR" }}                         → read env var
{{ output "brew" "--prefix" | trim }}      → run command, capture output
{{ lookPath "brew" }}                      → find executable path (empty if not found)
```

### Secret management
```
{{ bitwarden "item-id" }}
{{ onepassword "item" "vault" "account" }}
{{ gopass "path/to/secret" }}
{{ pass "path/to/secret" }}
{{ keyring "service" "user" }}             → OS keychain
```

## .chezmoiignore with Templates

```
README.md
LICENSE

{{ if ne .chezmoi.os "darwin" }}
.config/homebrew
{{ end }}

{{ if ne .chezmoi.os "linux" }}
.config/i3
{{ end }}

{{ if not .is_work }}
.config/work-tools
{{ end }}
```

## Template Debugging

```bash
# Show available template data
chezmoi data

# Execute template and show output
chezmoi execute-template '{{ .chezmoi.os }}'

# Execute template file
chezmoi execute-template < file.tmpl

# Show what a managed file would look like after template processing
chezmoi cat ~/.zshrc
```
