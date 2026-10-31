# Brewfile - Nix未対応/macOS専用パッケージのみ
# CLIツールはNix Home Manager (home.nix) で管理
# Usage: brew bundle --file=Brewfile

# ====================
# Taps
# ====================
tap "daipeihust/tap"

# ====================
# Runtime / Package Managers
# ====================
brew "mise"                           # ランタイム管理 (node/python/go等)
brew "uv"                             # Python パッケージマネージャ
brew "pipx"                           # Python アプリインストーラ
brew "python@3.12"                    # uv 等の依存
brew "php"                            # nvim PHP: intelephense LSP / pint formatter 用

# ====================
# CLI / Shell
# ====================
brew "thefuck"                        # zsh.nix の fuck() 関数で参照
brew "daipeihust/tap/im-select"       # nvim init.lua の IME 自動切替で使用
brew "bash"                           # macOS 標準より新しい bash 5.x
brew "bash-completion@2"
brew "tmux"                           # ターミナルマルチプレクサ
brew "tree"                           # ディレクトリツリー表示
brew "presenterm"                     # ターミナルプレゼンツール

# ====================
# Cloud / Deployment Tools
# ====================
brew "cloudflared"                    # Cloudflare Tunnel

# ====================
# Media / Utilities
# ====================
brew "ffmpeg"
brew "poppler"                        # PDF処理

# ====================
# Cask (GUI Apps)
# ====================
cask "ghostty"
cask "macskk"                         # 日本語 SKK 入力メソッド。設定は home-manager/macskk.nix で宣言的に管理

# ====================
# Fonts
# ====================
cask "font-hack-nerd-font"
