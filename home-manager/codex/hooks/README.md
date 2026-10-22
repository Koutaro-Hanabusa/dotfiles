# KB 保存判断 hook

Codex の Stop 時に、最終回答に再利用可能な確認済み知見があるかを Cloudflare Clef に判定させます。確率が 0.8 以上のときだけ、`~/.kb/home` または `~/.kb/work` で専用の `codex exec` をバックグラウンド起動し、既存の kb を検索して記録するよう固定文面で依頼します。対象 notebook のディレクトリと Nix profile の `codex` が必要です。0.8 は実データで校正していない暫定値です。

既定では無効です。有効化には `CODEX_KB_AUTO_SAVE=1`、32 文字の16進数の `CLOUDFLARE_ACCOUNT_ID`、`CLOUDFLARE_API_TOKEN`、対象を明示する `CODEX_KB_NOTEBOOK=home` または `work` が必要です。`CF_ACCESS_CLIENT_ID` と `CF_ACCESS_CLIENT_SECRET` は MCP 向けの Access 認証情報であり、この API token の代わりにはなりません。

後から有効化する手順:

1. [対象の Cloudflare Account ID](https://developers.cloudflare.com/fundamentals/account/find-account-and-zone-ids/) と API token を用意します。[Workers AI の公式手順](https://developers.cloudflare.com/workers-ai/get-started/rest-api/) にある Workers AI - Read と Workers AI - Edit、[AI Search の検索手順](https://developers.cloudflare.com/ai-search/api/search/rest-api/) にある AI Search:Edit と AI Search:Run の権限が必要です。対象 Account に限定してください。
2. `nvim ~/.zsh_secrets` などで、次の2行を追加します。値はダミーです。秘密値を README やリポジトリに記載しないでください。

   ```sh
   export CLOUDFLARE_ACCOUNT_ID='your-32-char-hex-account-id'
   export CLOUDFLARE_API_TOKEN='your-api-token'
   ```

3. 利用する zsh で `source ~/.zsh_secrets` を実行します。通常の zsh 起動時も Home Manager の設定がこのファイルを読み込みます。hook 自体は秘密ファイルを読まず、Codex プロセスへ export された値だけを使います。
4. 値を表示せず、設定の有無だけ確認します。これは通信や API 権限の確認ではありません。

   ```sh
   python3 -c 'import os; print("Account ID:", bool(os.getenv("CLOUDFLARE_ACCOUNT_ID")), "API token:", bool(os.getenv("CLOUDFLARE_API_TOKEN")))'
   ```

5. 初回は新しい CLI プロセスで `CODEX_KB_AUTO_SAVE=1 CODEX_KB_NOTEBOOK=home codex --no-daemon` を実行します。work を対象にする場合は `home` を `work` に変えます。`--no-daemon` は共有のバックグラウンドサーバーを使わずに起動します。起動済みの GUI や daemon へ環境変数が反映される前提にはしません。新規・変更された hook は [Codex の手順](https://learn.chatgpt.com/docs/hooks#review-and-trust-hooks) に従い `/hooks` から内容を確認し、信頼する場合だけ許可してください。判定できた場合は確率・閾値・保存依頼の有無を表示し、AI Search・Clef の失敗や不正応答、処理例外も短く表示します。「バックグラウンド保存を開始」は起動を示し、保存完了ではありません。無効化・入力不足・再帰や判定済みターンでは出力しません。

最終回答の先頭 2,000 文字を選択した notebook の [AI Search](https://developers.cloudflare.com/ai-search/api/search/rest-api/) に送り、R2 の Markdown と Vectorize に基づく既存候補を最大 3 件取得します。クエリ書換は無効です。成功して 0 件なら空の候補で判定し、検索失敗なら Clef を呼ばず終了します。各候補本文は先頭 4,000 文字まで Clef へ渡します。[Clef](https://developers.cloudflare.com/workers-ai/models/clef/) には最終回答の先頭 2 万文字、既存候補、notebook 名を送ります。会話ログ、会話中のツール入出力、システム指示は直接読みません。最終回答に書かれていない知見や長文の末尾は判定できません。R2/AI Search とローカル kb の同期には遅延があり得るため、保存を依頼された Codex が最新のローカル本文を再確認します。

[Workers AI のデータ利用説明](https://developers.cloudflare.com/workers-ai/platform/data-usage/) ではモデル学習に使用されませんが、保持には例外があります。AI Search と AI Gateway の保持・モデル設定は別で、実環境では未確認です。日本語での判定精度も未検証です。

低確率の判定後と高確率での子プロセス起動後は `~/.cache/codex-kb-save/` に本文や認証情報を含まない印を残し、重複呼び出しを避けます。判定や起動の失敗時は印を残さず、次回再試行できます。起動後の子プロセスの成否は追跡せず、失敗しても自動再試行しません。

ネットワークや実際の kb を使わずにテストできます。

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s home-manager/codex/hooks -p 'test_*.py'
```
