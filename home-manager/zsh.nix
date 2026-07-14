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

    profileExtra = ''
      # Homebrew（旧 ~/.zprofile から移植。home-manager が .zprofile を生成するように
      # なった際に -b backup で退避されたため、ここで管理する）
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';

    envExtra = ''
      # zoxide doctor の誤検知警告を抑止
      # （home-manager は zoxide 初期化を zshrc 先頭に置くが、その後 direnv 等の
      #  chpwd フックが登録されるため「最後に初期化しろ」と毎回警告が出る。zoxide
      #  自体は正常動作しており機能影響はないため、公式の抑止フラグで黙らせる）
      export _ZO_DOCTOR=0

      # Claude Code は Nix (nix-claude-code overlay) 管理に移行済み。
      # 実バイナリは ~/.nix-profile/bin/claude、ラッパーは下の claude() 関数を参照。
      export PATH="$HOME/.local/bin:$PATH"
      # nix-claude-code の makeWrapper でも設定済みだが、shell 直起動の互換のため残す
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
      # Claude / Codex は Nix 管理に移行済みだが、vp 自体（Node ランタイム管理等）は残す。
      # 下記の関数ラッパーで ~/.vite-plus/bin/{claude,codex} shim をバイパスする。
      [ -f "$HOME/.vite-plus/env" ] && . "$HOME/.vite-plus/env"

      # `claude` は現在の Home Manager profile 経由で実行する（vp shim をバイパス、MCP 定義を明示読み込み）
      claude() {
        command "$HOME/.nix-profile/bin/claude" --mcp-config ~/.mcp.json "$@"
      }

      # `codex` も同様に現在の Home Manager profile 経由で実行する（vp shim をバイパス）
      codex() {
        command "$HOME/.nix-profile/bin/codex" "$@"
      }

      # `hunk diff`（ターゲットなし）は unstaged のみ表示で、git add した変更が
      # 差分から消えてしまう。HEAD 比較なら staged + unstaged の両方が見えるので、
      # ターゲット未指定かつ --staged/--cached でない場合だけ HEAD を自動挿入する。
      hunk() {
        if [[ "$1" == "diff" ]]; then
          shift
          local arg has_target=0
          for arg in "$@"; do
            [[ "$arg" == "--" ]] && break
            [[ "$arg" == "--staged" || "$arg" == "--cached" ]] && has_target=1 && break
            [[ "$arg" != -* ]] && has_target=1 && break
          done
          if (( has_target )); then
            command hunk diff "$@"
          else
            command hunk diff HEAD "$@"
          fi
        else
          command hunk "$@"
        fi
      }

      _open_herdr_editor_split() {
        # 注意: interactive / -t チェックは入れない。
        # nvim() から `$()` 経由で呼ばれた subshell は非インタラクティブかつ stdout がパイプ
        # なので、それらを条件にすると split が絶対に生えない。
        # HERDR_PANE_ID は herdr pane 内でしか set されないので、これだけで判定に十分。
        [[ -n "''${HERDR_PANE_ID:-}" ]] || return 0
        command -v herdr >/dev/null 2>&1 || return 0
        command -v jq >/dev/null 2>&1 || return 0

        # `herdr pane split --current --direction right` は現在の pane を分割するため、
        # ワークスペースの右端かどうかに関わらず常に成功する。
        # ratio 0.7 → 元 pane が 70%、右 split が 30% になる。
        local split_output
        split_output=$(command herdr pane split --current --direction right --ratio 0.7 --cwd "$PWD" --no-focus 2>/dev/null) || return 0
        printf '%s' "$split_output" | command jq -r '.result.pane.pane_id // empty' 2>/dev/null
      }

      nvim() {
        case " $* " in
          *" --headless "*|*" --version "*|*" --help "*|*" -v "*|*" -h "*)
            command nvim "$@"
            ;;
          *)
            local herdr_editor_split_pane_id
            herdr_editor_split_pane_id=$(_open_herdr_editor_split)
            command nvim "$@"
            local nvim_status=$?
            if [[ -n "$herdr_editor_split_pane_id" ]]; then
              command herdr pane close "$herdr_editor_split_pane_id" >/dev/null 2>&1 || true
            fi
            return $nvim_status
            ;;
        esac
      }

      vim() {
        nvim "$@"
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
