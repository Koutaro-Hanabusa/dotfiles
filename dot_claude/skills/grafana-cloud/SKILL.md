---
name: grafana-cloud
description: >
  Query Grafana Cloud for Claude Code usage analytics. Triggers at session start
  to show a brief usage summary, and when user asks about costs, tokens, tool usage,
  errors, or performance. Manually invoke with /grafana.
---

# Grafana Cloud Usage Analytics

Claude CodeのOTelメトリクス・ログをGrafana Cloudから取得し、使用状況を分析するスキル。

## 認証

```bash
# APIキーをロード（~/.zsh_secrets に GRAFANA_CLOUD_API_KEY が定義されている）
source ~/.zsh_secrets
```

## エンドポイント

| サービス | URL | ユーザーID |
|---------|-----|-----------|
| Loki | `https://logs-prod-030.grafana.net` | `1497154` |
| Prometheus | `https://prometheus-prod-49-prod-ap-northeast-0.grafana.net` | `3002958` |

## PC種別の区別

OTelデータには `pc_type` ラベルが付与されている:
- `home` — 自宅PC
- `work` — 会社PC（`~/.is_work_pc` が存在する環境）

クエリ時に `pc_type` でフィルタ可能。デフォルトでは全PCの合計を表示し、PC種別ごとの内訳も表示する。

## セッション開始時の自動サマリー

新しいセッションの最初に、以下の簡易サマリーを表示する:

```
📊 Claude Code Usage Summary (Today)
┌─────────────┬──────────┬──────────┐
│             │ Home     │ Work     │
├─────────────┼──────────┼──────────┤
│ Cost        │ $X.XX    │ $X.XX    │
│ Tokens      │ XXK      │ XXK      │
│ Errors      │ X        │ X        │
└─────────────┴──────────┴──────────┘
```

### サマリー取得手順

1. `source ~/.zsh_secrets` でAPIキーをロード
2. 現在時刻を `mcp__time__get_current_time` で取得
3. 以下の3クエリを**並列実行**:
   - 今日のコスト合計（PC別）
   - 今日のトークン消費量（PC別）
   - 直近24hのエラー件数（PC別）
4. テーブル形式で出力

## 手動 `/grafana` — 詳細レポート

ユーザーが `/grafana` を実行、またはコスト・トークン・パフォーマンスについて質問した場合、以下の詳細レポートを生成する。

### レポート項目

1. **コスト分析**
   - 今日/今週/今月の合計コスト（PC別）
   - モデル別コスト内訳
   - 日別コスト推移（直近7日）

2. **トークン分析**
   - トークン種別内訳: input / output / cache_read / cache_creation
   - PC別トークン使用量
   - 日別推移（直近7日）

3. **ツール使用ランキング**
   - OTelログから `tool_result` イベントを集計
   - 上位10ツールの使用回数

4. **Subagent/Skill使用状況**
   - hooksログ（`job="claude-hooks"`）から集計
   - subagent_type別の呼び出し回数
   - skill別の呼び出し回数
   - PC別の内訳

5. **APIパフォーマンス**
   - レスポンスタイム: p50 / p95
   - 直近1時間の推移

6. **キャッシュヒット率**
   - cache_read_tokens / (input_tokens + cache_read_tokens)
   - PC別の比較

7. **エラー一覧**
   - 直近24hの api_error
   - ツール実行失敗
   - PC別の内訳

### レポート出力フォーマット

- テーブル形式（Markdownテーブル）
- 金額は `$X.XX` 表記
- トークンは `K`（千）/ `M`（百万）単位
- パーセンテージは `XX.X%` 表記
- PC種別は Home / Work で区別

## API呼び出し方法

### Loki クエリ (LogQL)

```bash
source ~/.zsh_secrets
curl -s -u "1497154:$GRAFANA_CLOUD_API_KEY" \
  "https://logs-prod-030.grafana.net/loki/api/v1/query_range" \
  --data-urlencode 'query={job="claude-code"} |= "api_request" | json' \
  --data-urlencode 'start=<RFC3339_START>' \
  --data-urlencode 'end=<RFC3339_END>' \
  --data-urlencode 'limit=5000'
```

### Prometheus クエリ (PromQL)

```bash
source ~/.zsh_secrets
curl -s -u "3002958:$GRAFANA_CLOUD_API_KEY" \
  "https://prometheus-prod-49-prod-ap-northeast-0.grafana.net/api/prom/api/v1/query" \
  --data-urlencode 'query=sum(claude_code_cost_usage_USD_total)'
```

### Prometheus Range クエリ

```bash
source ~/.zsh_secrets
curl -s -u "3002958:$GRAFANA_CLOUD_API_KEY" \
  "https://prometheus-prod-49-prod-ap-northeast-0.grafana.net/api/prom/api/v1/query_range" \
  --data-urlencode 'query=sum(claude_code_cost_usage_USD_total)' \
  --data-urlencode 'start=<UNIX_TIMESTAMP_START>' \
  --data-urlencode 'end=<UNIX_TIMESTAMP_END>' \
  --data-urlencode 'step=3600'
```

## クエリリファレンス

詳細なクエリ定義は [references/queries.md](references/queries.md) を参照。

## 注意事項

- Loki の `query_range` はデフォルトで最大5000件。大量データの場合は期間を短くする
- Prometheus メトリクスは Delta→Cumulative 変換済みのため、`rate()` や `increase()` が使える
- APIキーは `~/.zsh_secrets` に格納。絶対にログや出力に含めないこと
- PC種別でフィルタする場合は `pc_type="home"` または `pc_type="work"` を使用
