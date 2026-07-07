{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      # モダンCLIツールのエイリアス
      cat = "bat";
      ls = "eza --icons --git";
      ll = "eza -la --icons --git";
      la = "eza -a --icons --git";
      tree = "eza --tree --icons";
      grep = "rg";

      # 開発ツール
      vim = "nvim";
    };

    sessionVariables = {
      # Git prompt 表示設定
      GIT_PS1_SHOWDIRTYSTATE = "1";
      GIT_PS1_SHOWUNTRACKEDFILES = "1";
      GIT_PS1_SHOWSTASHSTATE = "1";

      # Claude Code OpenTelemetry モニタリング (→ Grafana Cloud)
      CLAUDE_CODE_ENABLE_TELEMETRY = "1";
      OTEL_METRICS_EXPORTER = "otlp";
      OTEL_LOGS_EXPORTER = "otlp";
      OTEL_EXPORTER_OTLP_PROTOCOL = "grpc";
      OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4317";
    };

    envExtra = ''
      # zoxide doctor の誤検知警告を抑止
      # （home-manager は zoxide 初期化を zshrc 先頭に置くが、その後 direnv 等の
      #  chpwd フックが登録されるため「最後に初期化しろ」と毎回警告が出る。zoxide
      #  自体は正常動作しており機能影響はないため、公式の抑止フラグで黙らせる）
      export _ZO_DOCTOR=0

      # Claude Code は vite-plus(vp) 管理の install に一本化
      export PATH="$HOME/.local/bin:$PATH"
      # 多数の同時セッションが共有prefixを奪い合い自動更新が暴走するため無効化（更新は手動 `claude update`）
      export DISABLE_AUTOUPDATER="1"
      # miseのshimsをPATHに追加（Claude Code等の非インタラクティブ環境用）
      export PATH="$HOME/.local/share/mise/shims:$PATH"
      # node_modules/.bin をPATHに追加（npxなしでローカルCLIを実行可能に）
      export PATH="./node_modules/.bin:$PATH"
      # ~/bin（waza 等の手動インストールバイナリ）
      export PATH="$HOME/bin:$PATH"
    '';

    initContent = ''
      # mise - ランタイムバージョン管理（node, python, go等）
      eval "$(mise activate zsh)"

      # Go バイナリへのパス
      export PATH="$HOME/go/bin:$PATH"

      # Vite+ (vp): PATH + vp関数ラッパー + zsh補完
      [ -f "$HOME/.vite-plus/env" ] && . "$HOME/.vite-plus/env"

      # Codex CLI は vite-plus(vp) の PATH 解決に任せる（~/.vite-plus/bin/codex -> vp）

      # `claude` は常に実バイナリを起動（user スコープ外の MCP 定義を明示読み込み）
      claude() {
        command "$HOME/.vite-plus/bin/claude" --mcp-config ~/.mcp.json "$@"
      }

      # Git公式のgit-prompt.shを使用してブランチ名を表示（Nix管理のgitパッケージから読み込み）
      source ${pkgs.git}/share/git/contrib/completion/git-prompt.sh

      setopt PROMPT_SUBST
      PROMPT='%n@%m %F{blue}%~%f %F{208}$(__git_ps1 "(%s)")%f%# '

      # ローカル環境固有のシークレット（GRAFANA_CLOUD_API_KEY, GRAFANA_*_URL/USER等）
      [ -f ~/.zsh_secrets ] && source ~/.zsh_secrets

      # AWSログイン & SSHトンネリング（i, o エイリアス）
      [ -f ~/.zsh_tunneling ] && source ~/.zsh_tunneling

      # ghq + fzf: リポジトリ選択してcd（Ctrl+Gで起動）
      ghq-fzf() {
        local repo
        repo=$(ghq list -p | fzf --preview "eza --icons --git -la {}")
        if [[ -n "$repo" ]]; then
          cd "$repo"
          zle accept-line
        else
          zle reset-prompt
        fi
      }
      zle -N ghq-fzf
      bindkey '^G' ghq-fzf

      # マークダウン表示（glow > less）
      _show_md() {
        if command -v glow &> /dev/null; then
          glow -p "$1"
        else
          less "$1"
        fi
      }

      # fzf でブランチをファジー検索して切り替え
      gco() {
        local branch
        branch=$(command git branch --format='%(refname:short)' | fzf --query="$1" --select-1 --exit-0)
        if [[ -n "$branch" ]]; then
          git switch "$branch"
        fi
      }

      # ブランチ名規約チェック（checkout -b / switch -c 時に自動警告）
      git() {
        command git "$@"
        local exit_code=$?
        if [[ $exit_code -eq 0 && \
              (("$1" == "checkout" && " $* " == *" -b "*) || \
               ("$1" == "switch" && " $* " == *" -c "*)) ]]; then
          local branch
          branch=$(command git symbolic-ref --short HEAD 2>/dev/null)
          local pattern='^(feature|fix|hotfix|release|chore|refactor|docs|test|ci|perf|build)/[0-9]+-[a-z0-9-]+$'
          if [[ -n "$branch" && ! "$branch" =~ $pattern ]]; then
            print -P "\n%F{yellow}⚠️  ブランチ名が推奨パターンに沿っていません: %F{red}$branch%f"
            print -P "   %F{white}推奨: %F{green}<type>/<TICKET番号>-<short-summary>%f"
            print -P "   %F{white}例:   %F{green}feature/55-add-login-page%f"
          fi
        fi
        return $exit_code
      }

      # タイポ修正（遅延ロード: 初回呼び出し時にのみ読み込み）
      fuck() {
        unfunction fuck
        eval $(thefuck --alias)
        fuck "$@"
      }

      # ── nb ナレッジ（ターミナル完結: fzf + glow/nvim） ──

      # nbナレッジをfzfでブラウズして閲覧
      nbo() {
        local file
        if [[ -n "$1" ]]; then
          file=$(fd -e md . "$HOME/.nb/$1" | fzf --preview "glow -s dark {}" --preview-window=right:60%)
        else
          file=$({ fd -e md . "$HOME/.nb/home/knowledge" 2>/dev/null; fd -e md . "$HOME/.nb/work/knowledge" 2>/dev/null; } | fzf --preview "glow -s dark {}" --preview-window=right:60%)
        fi
        [[ -z "$file" ]] && return
        _show_md "$file"
      }

    '';
  };
}
