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

**重要**: `~/.zsh_secrets` はzsh固有の構文を含むため、必ず `zsh -c` 経由で実行すること。

```bash
# 正しい呼び出し方法（bashからの場合）
zsh -c 'source ~/.zsh_secrets && curl ...'

# 直接 source ~/.zsh_secrets は bash では動作しない
```

## エンドポイント

| サービス | ベースURL | ユーザーID | 読み取りパス |
|---------|----------|-----------|------------|
| Loki | `https://logs-prod-030.grafana.net` | `1497154` | `/loki/api/v1/query`, `/loki/api/v1/query_range` |
| Prometheus | `https://prometheus-prod-49-prod-ap-northeast-0.grafana.net` | `3002958` | `/api/prom/api/v1/query`, `/api/prom/api/v1/query_range` |

## データ構造

### Prometheus メトリクス（実際に存在するもの）

| メトリクス名 | 説明 | ラベル |
|-------------|------|--------|
| `claude_code_cost_usage_USD_total` | コスト（USD） | `model`, `session_id`, `terminal_type`, `pc_type` |
| `claude_code_token_usage_tokens_total` | トークン数 | `model`, `type`, `session_id`, `terminal_type`, `pc_type` |
| `claude_code_active_time_seconds_total` | アクティブ時間 | `session_id`, `pc_type` |
| `claude_code_session_count_total` | セッション数 | `pc_type` |
| `claude_code_commit_count_total` | コミット数 | `pc_type` |
| `claude_code_lines_of_code_count_total` | コード行数 | `pc_type` |
| `claude_code_code_edit_tool_decision_total` | 編集ツール決定数 | `pc_type` |

**トークン `type` ラベル値**: `input`, `output`, `cacheRead`, `cacheCreation`

### Loki ログ

**job="claude-code"** (OTel経由):
- ラベル: `service_name`, `exporter=OTLP`, `detected_level` (info/error/warn)
- ログ本文はJSON。`| json` パイプラインで属性展開
- 主要属性: `body` にイベント詳細

**job="claude-hooks"** (Promtail経由):
- ラベル: `tool_name`, `subagent_type`, `skill`, `pc_type`
- ログ本文はJSON: `timestamp`, `tool_name`, `subagent_type`, `skill`, `description`, `prompt`, `args`

## PC種別の区別

OTelコレクターの `resource` プロセッサで `pc_type` ラベルが自動付与される:
- `home` — 自宅PC（デフォルト）
- `work` — 会社PC（`~/.is_work_pc` が存在する環境）

Promtailのhooksログにも同様に `pc_type` ラベルが付与される。

**注意**: `pc_type` ラベルは2026-02-26以降のデータにのみ存在。それ以前のデータにはこのラベルがない。
クエリ時は `pc_type` がないデータも考慮し、`by (pc_type)` での集計が空でもエラーにならないようにする。

## セッション開始時の自動サマリー

新しいセッションの最初に、以下の簡易サマリーを表示する:

```
Claude Code Usage Summary (Today)
┌─────────────┬──────────┬──────────┐
│             │ Home     │ Work     │
├─────────────┼──────────┼──────────┤
│ Cost        │ $X.XX    │ $X.XX    │
│ Tokens      │ XXK      │ XXK      │
│ Errors      │ X        │ X        │
└─────────────┴──────────┴──────────┘
```

### サマリー取得手順

1. 現在時刻を `mcp__time__get_current_time` (timezone: Asia/Tokyo) で取得
2. 以下の3クエリを `zsh -c` 経由で**並列実行**:
   - 今日のコスト合計（PC別）: `sum by (pc_type)(claude_code_cost_usage_USD_total)`
   - 今日のトークン消費量（PC別）: `sum by (pc_type)(claude_code_token_usage_tokens_total)`
   - 直近24hのエラー件数（PC別）: Lokiで `{job="claude-code"} |= "error"` を `count_over_time`
3. テーブル形式で出力

## 手動 `/grafana` — 詳細レポート

ユーザーが `/grafana` を実行、またはコスト・トークン・パフォーマンスについて質問した場合、以下の詳細レポートを生成する。

### レポート項目

1. **コスト分析**
   - 今日/今週/今月の合計コスト（PC別）
   - モデル別コスト内訳: `sum by (model, pc_type)(claude_code_cost_usage_USD_total)`
   - 日別コスト推移（直近7日）

2. **トークン分析**
   - トークン種別内訳: `sum by (type, pc_type)(claude_code_token_usage_tokens_total)`
   - type値: `input`, `output`, `cacheRead`, `cacheCreation`
   - 日別推移（直近7日）

3. **ツール使用ランキング**
   - OTelログ（Loki `job="claude-code"`）から集計
   - 上位10ツールの使用回数

4. **Subagent/Skill使用状況**
   - hooksログ（Loki `job="claude-hooks"`）から集計
   - `subagent_type` 別の呼び出し回数
   - `skill` 別の呼び出し回数
   - PC別の内訳

5. **キャッシュヒット率**
   - `cacheRead / (input + cacheRead)` で算出
   - PC別の比較

6. **セッション統計**
   - セッション数: `claude_code_session_count_total`
   - アクティブ時間: `claude_code_active_time_seconds_total`
   - コミット数: `claude_code_commit_count_total`

7. **エラー一覧**
   - 直近24hのLokiエラーログ: `{job="claude-code", detected_level="error"}`
   - PC別の内訳

### レポート出力フォーマット

- テーブル形式（Markdownテーブル）
- 金額は `$X.XX` 表記
- トークンは `K`（千）/ `M`（百万）単位
- パーセンテージは `XX.X%` 表記
- PC種別は Home / Work で区別

## API呼び出し方法

### Prometheus instant query

```bash
zsh -c 'source ~/.zsh_secrets && curl -s -u "3002958:$GRAFANA_CLOUD_API_KEY" \
  "https://prometheus-prod-49-prod-ap-northeast-0.grafana.net/api/prom/api/v1/query" \
  --data-urlencode "query=sum by (pc_type)(claude_code_cost_usage_USD_total)"'
```

### Prometheus range query

```bash
zsh -c 'source ~/.zsh_secrets && \
  START=$(date -v-7d +%s) && \
  END=$(date +%s) && \
  curl -s -u "3002958:$GRAFANA_CLOUD_API_KEY" \
    "https://prometheus-prod-49-prod-ap-northeast-0.grafana.net/api/prom/api/v1/query_range" \
    --data-urlencode "query=sum(claude_code_cost_usage_USD_total)" \
    --data-urlencode "start=$START" \
    --data-urlencode "end=$END" \
    --data-urlencode "step=86400"'
```

### Loki instant query

```bash
zsh -c 'source ~/.zsh_secrets && curl -s -u "1497154:$GRAFANA_CLOUD_API_KEY" \
  "https://logs-prod-030.grafana.net/loki/api/v1/query" \
  --data-urlencode "query=sum by (subagent_type)(count_over_time({job=\"claude-hooks\", tool_name=\"Task\"} [24h]))"'
```

### Loki query_range

```bash
zsh -c 'source ~/.zsh_secrets && \
  START=$(date -u -v-24H +%Y-%m-%dT%H:%M:%SZ) && \
  END=$(date -u +%Y-%m-%dT%H:%M:%SZ) && \
  curl -s -u "1497154:$GRAFANA_CLOUD_API_KEY" \
    "https://logs-prod-030.grafana.net/loki/api/v1/query_range" \
    --data-urlencode "query={job=\"claude-code\", detected_level=\"error\"}" \
    --data-urlencode "start=$START" \
    --data-urlencode "end=$END" \
    --data-urlencode "limit=100"'
```

## クエリリファレンス

詳細なクエリ定義は [references/queries.md](references/queries.md) を参照。

## 注意事項

- **必ず `zsh -c '...'` で実行する**（bashでは `~/.zsh_secrets` のsourceが失敗する）
- Loki の `query_range` はデフォルトで最大5000件。大量データの場合は期間を短くする
- Prometheus メトリクスは Delta→Cumulative 変換済みのため `rate()` や `increase()` が使える
- APIキーは `~/.zsh_secrets` に格納。**絶対にログや出力に含めないこと**
- PC種別フィルタ: `pc_type="home"` or `pc_type="work"`（2026-02-26以降のデータのみ）
- curlレスポンスは `| jq .` でパースしてから値を抽出する
