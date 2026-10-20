# KB 保存判断 hook

Codex の Stop 時に、最終回答に再利用可能な確認済み知見があるかを Cloudflare Clef に判定させます。確率が 0.8 以上のときだけ、Codex に既存の kb を検索して記録するよう固定文面で依頼します。0.8 は実データで校正していない暫定値です。hook 自体は kb を更新しません。

既定では無効です。有効化には `CODEX_KB_AUTO_SAVE=1`、32 桁の `CLOUDFLARE_ACCOUNT_ID`、`CLOUDFLARE_API_TOKEN`、対象を明示する `CODEX_KB_NOTEBOOK=home` または `work` を環境変数として Codex プロセスに渡します。値の例は `CLOUDFLARE_ACCOUNT_ID=0123456789abcdef0123456789abcdef`、`CLOUDFLARE_API_TOKEN=your-token` です。token には Workers AI の実行権限に加え、[AI Search の権限案内](https://developers.cloudflare.com/ai-search/api/search/rest-api/) に従い AI Search:Edit と AI Search:Run が必要です。新しい認証設定は行っていません。既存の秘密ファイルは読み込みません。設定変更後、Codex の再起動や hook の trust レビューが必要になる場合があります。

最終回答の先頭 2,000 文字を選択した notebook の [AI Search](https://developers.cloudflare.com/ai-search/api/search/rest-api/) に送り、R2 の Markdown と Vectorize に基づく既存候補を最大 3 件取得します。クエリ書換は無効です。成功して 0 件なら空の候補で判定し、検索失敗なら Clef を呼ばず終了します。各候補本文は先頭 4,000 文字まで Clef へ渡します。[Clef](https://developers.cloudflare.com/workers-ai/models/clef/) には最終回答の先頭 2 万文字、既存候補、notebook 名を送ります。会話ログ、会話中のツール入出力、システム指示は直接読みません。最終回答に書かれていない知見や長文の末尾は判定できません。R2/AI Search とローカル kb の同期には遅延があり得るため、保存を依頼された Codex が最新のローカル本文を再確認します。

[Workers AI のデータ利用説明](https://developers.cloudflare.com/workers-ai/platform/data-usage/) ではモデル学習に使用されませんが、保持には例外があります。AI Search と AI Gateway の保持・モデル設定は別で、実環境では未確認です。日本語での判定精度も未検証です。

判定成功済みのターンは `~/.cache/codex-kb-save/` に本文や認証情報を含まない印を残し、重複呼び出しを避けます。失敗時は印を残しません。

ネットワークや実際の kb を使わずにテストできます。

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s home-manager/codex/hooks -p 'test_*.py'
```
