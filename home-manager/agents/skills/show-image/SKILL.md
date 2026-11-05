---
name: show-image
description: スクリーンショット、生成した画像、図などをユーザーに見せたいとき、フロントエンドの UI 変更をユーザーと同じ画面で確認したいときに使う。エージェントの TUI は画像を描画できないため、隣の herdr ペインに表示する。
---

# Show Image

エージェントのコマンド出力は画面に直接届かないので、`herdr` で隣にペインを開き、そこで `chafa` に Kitty graphics で描画させる。herdr TUI と Ghostty の組み合わせで表示を確認済み。

```sh
pane=$(herdr pane split --current --direction right --ratio 0.4 | jq -r .result.pane.pane_id)
herdr pane run "$pane" "clear; chafa -f kitty '/abs/path/to/image.png'"
```

- ブラウザの画面は Playwright や chrome-devtools の MCP でスクリーンショットをファイルに保存してから表示する。
- 続けて見せるときは同じ `$pane` に `herdr pane run` し直し、ペインを増やさない。
- 見せ終わったら `herdr pane close "$pane"` で閉じる。
- `herdr pane current` が失敗する（herdr の外で動いている）ときは、`open <file>` で macOS のプレビューを開く。
