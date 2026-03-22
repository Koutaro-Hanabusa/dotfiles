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
      sail = "bash vendor/bin/sail";
      claude = "command claude --mcp-config ~/.claude/mcp.json";
      vim = "nvc";
      gg = "ghq-get-cd";

      # ヘルプ
      dothelp = "_show_md ~/dotfiles/README.md";
      vimhelp = "_show_md ~/.config/nvim/doc/README.md";

      # その他
      chrome = ''open -na "Google Chrome" --args --new-window'';
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
      # miseのshimsをPATHに追加（Claude Code等の非インタラクティブ環境用）
      export PATH="$HOME/.local/share/mise/shims:$PATH"
    '';

    initContent = ''
      # mise - ランタイムバージョン管理（node, python, go等）
      eval "$(mise activate zsh)"

      # Go バイナリへのパス
      export PATH="$HOME/go/bin:$PATH"

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

      # ghqで取得してすぐcdするショートカット
      ghq-get-cd() {
        ghq get "$@" && cd "$(ghq list -p | fzf --query "''${@##*/}" --select-1)"
      }

      # nvim + tmux: 右にClaude用ターミナルを分割して起動
      nvc() {
        local target="''${1:-.}"
        if [[ -n "$TMUX" ]]; then
          local split_pane_id
          split_pane_id=$(tmux split-window -h -c "$(pwd)" -p 25 -P -F '#{pane_id}')
          tmux select-pane -L
          # nvimペインだけallow-passthrough有効化（image.nvim用）
          tmux set-option -p allow-passthrough on
          command nvim "$target"
          tmux kill-pane -t "$split_pane_id" 2>/dev/null
          return
        fi
        local session_name="nvc-$$-$RANDOM"
        tmux new-session -d -s "$session_name" -c "$(pwd)"
        # nvimペインだけallow-passthrough有効化（image.nvim用）
        tmux set-option -t "$session_name:1.1" -p allow-passthrough on
        tmux send-keys -t "$session_name" "nvim $target; tmux kill-session -t $session_name" Enter
        tmux split-window -h -t "$session_name" -c "$(pwd)" -p 10
        tmux select-pane -t "$session_name:1.1"
        tmux attach-session -t "$session_name"
      }

      # ヘルプ表示（glowがあれば使う、なければless）
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

      # ── Obsidian CLI × nb 連携 ──

      # Obsidian TUI を起動（nb ナレッジをブラウズ）
      # TUI 内で `/nb-` と打つとnbフォルダだけにフィルタできる
      alias nbo="obsidian"

      # nb ナレッジを全文検索してObsidian の検索ビューで開く
      nbs() {
        local query="''${1:?Usage: nbs <検索ワード>}"
        obsidian search:open query="path:nb- $query"
      }

      # nbのタイムスタンプ名ファイルにタイトルをリネーム
      nb-organize() {
        local folder="''${1:-nb-home-knowledge}"
        local count=0
        obsidian files folder="$folder" | while read -r filepath; do
          local basename="''${filepath##*/}"
          # タイムスタンプ名（数字のみ.md）のファイルだけ対象
          if [[ "$basename" =~ ^[0-9]+\.md$ ]]; then
            local title
            title=$(obsidian read path="$filepath" 2>/dev/null | command head -1 | command sed -E 's/^#+ //')
            if [[ -n "$title" && "$title" != "" ]]; then
              # タイトルをファイル名に使える形に変換
              local safe_name
              safe_name=$(echo "$title" | command sed 's/[\/\\:*?"<>|]/-/g' | command sed 's/  */ /g' | command head -c 80)
              if [[ -n "$safe_name" ]]; then
                obsidian rename path="$filepath" name="$safe_name" 2>/dev/null && \
                  print -P "%F{green}✓%f $basename → $safe_name.md" && \
                  ((count++))
              fi
            fi
          fi
        done
        print -P "\n%F{blue}$count 件リネームしました%f"
      }
    '';
  };
}
