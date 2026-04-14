{ ... }:

{
  programs.tmux = {
    enable = true;
    prefix = "C-a";
    mouse = true;
    keyMode = "vi";
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 10000;
    terminal = "tmux-256color";

    extraConfig = ''
      # ペイン分割を直感的に
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # ペイン移動をVim風に
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # ペインのリサイズをVim風に
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # 256色対応（ghostty/xterm向けRGB/Tc設定）
      set -ga terminal-overrides ",xterm-ghostty:RGB,xterm-256color:Tc"

      # allow-passthroughはグローバルでoff（Claude Code TUIのスクロール飛び防止）
      # image.nvimが必要なnvimペインだけnvc関数内でper-pane有効化する
      set -g allow-passthrough off
      set -ga update-environment TERM_PROGRAM

      # ステータスバーをシンプルに
      set -g status-style bg=black,fg=white
      set -g status-left "[#S] "
      set -g status-right "%H:%M"

      # 新しいウィンドウを最新クライアントのサイズで開く（フルサイズ表示）
      set -g window-size latest
      setw -g aggressive-resize on

      setw -g pane-base-index 0

      # フォーカスイベント無効化（Claude Code TUIがフォーカスイベントで
      # スクロール位置をリセットする既知バグ回避: anthropics/claude-code#18299）
      set -g focus-events off

      # マウスモードのトグル（prefix + M で ON/OFF切替）
      bind M set -g mouse \; display "Mouse: #{?mouse,ON,OFF}"

      # コピーモード設定（システムクリップボード連携）
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi y send -X copy-pipe-and-cancel "pbcopy"
      bind -T copy-mode-vi Enter send -X copy-pipe-and-cancel "pbcopy"

      # マウスクリックはそのままアプリに転送（Claude Code TUI等の入力欄操作に必要）
    '';
  };
}
