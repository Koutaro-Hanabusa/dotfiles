# Brewfile - Nix未対応/macOS専用パッケージのみ
# CLIツールはNix Home Manager (home.nix) で管理
# Usage: brew bundle --file=Brewfile

# ====================
# Taps
# ====================
tap "daipeihust/tap"
tap "xwmx/taps"
tap "heroku/brew"

# ====================
# Runtime / Package Managers
# ====================
brew "mise"                           # ランタイム管理 (node/python/go等)
brew "uv"                             # Python パッケージマネージャ
brew "pipx"                           # Python アプリインストーラ
brew "python@3.12"                    # uv 等の依存
brew "php"                            # Laravel sail エイリアス用

# ====================
# CLI / Shell
# ====================
brew "thefuck"                        # zsh.nix の fuck() 関数で参照
brew "daipeihust/tap/im-select"       # nvim init.lua の IME 自動切替で使用
brew "nb"                             # always-active skill nb-knowledge で必須
brew "fish"                           # サブシェル
brew "bash"                           # macOS 標準より新しい bash 5.x
brew "bash-completion@2"
brew "tmux"                           # ターミナルマルチプレクサ
brew "tree"                           # ディレクトリツリー表示
brew "presenterm"                     # ターミナルプレゼンツール
brew "chezmoi"                        # dotfiles 管理（Nix と併用）

# ====================
# Database / Infra
# ====================
brew "mysql"
brew "postgresql@14"

# ====================
# Cloud / Deployment Tools
# ====================
brew "cloudflared"                    # Cloudflare Tunnel
brew "flyctl"                         # Fly.io CLI
brew "heroku/brew/heroku"             # Heroku CLI
brew "railway"                        # Railway CLI

# ====================
# Media / Utilities
# ====================
brew "ffmpeg"
brew "poppler"                        # PDF処理

# ====================
# Cask (GUI Apps)
# ====================
cask "cmux"
cask "ghostty"

# ====================
# Fonts
# ====================
cask "font-hack-nerd-font"
