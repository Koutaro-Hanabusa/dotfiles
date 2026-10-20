# KB 保存判断 hook

Codex の Stop 時に、最終回答に再利用可能な確認済み知見があるかを Cloudflare Clef に判定させます。確率が 0.8 以上のときだけ、Codex に既存の kb を検索して記録するよう固定文面で依頼します。0.8 は実データで校正していない暫定値です。hook 自体は kb を読み書きしません。

既定では無効です。有効化には `CODEX_KB_AUTO_SAVE=1`、32 桁の `CLOUDFLARE_ACCOUNT_ID`、`CLOUDFLARE_API_TOKEN` を環境変数として Codex プロセスに渡します。値の例は `CLOUDFLARE_ACCOUNT_ID=0123456789abcdef0123456789abcdef`、`CLOUDFLARE_API_TOKEN=your-token` です。既存の秘密ファイルは読み込みません。設定変更後、Codex の再起動や hook の trust レビューが必要になる場合があります。

送信先は固定の [Cloudflare Workers AI Clef API](https://developers.cloudflare.com/workers-ai/models/clef/) です。送る本文は Stop イベントの `last_assistant_message` の先頭 2 万文字だけです。transcript、ツール入出力、システム指示は読みません。最終回答に書かれていない知見や長文の末尾は判定できません。[Cloudflare のデータ利用説明](https://developers.cloudflare.com/workers-ai/platform/data-usage/) では Workers AI のデータはモデル学習に使用されませんが、保持には例外があり、日本語での判定精度は未検証です。

判定成功済みのターンは `~/.cache/codex-kb-save/` に本文や認証情報を含まない印を残し、重複呼び出しを避けます。失敗時は印を残しません。

ネットワークや実際の kb を使わずにテストできます。

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s home-manager/codex/hooks -p 'test_*.py'
```
