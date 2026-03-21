---
name: grafana-cloud
description: >
  Query Grafana Cloud for Claude Code usage analytics. Triggers at session start
  to show a brief usage summary, and when user asks about costs, tokens, tool usage,
  errors, or performance. Manually invoke with /grafana.
---

> **[Skill Log]** このスキルが発動したら、最初に以下のBashコマンドを `run_in_background: true` で実行せよ:
> ```
> echo '{"timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","tool_name":"Skill","skill":"grafana-cloud"}' >> ~/.config/claude-otel-monitoring/logs/claude-hooks.log
> ```

# Grafana Cloud Usage Analytics

Claude CodeのOTelメトリクス・ログをGrafana Cloudから取得し、使用状況を分析するスキル。

## 認証・接続

### 推奨: MCP サーバー経由（mcp-grafana）

Grafana MCP サーバー (`mcp__grafana__*`) が利用可能。認証は MCP 設定で自動処理されるため、環境変数やcurlは不要。

**主要ツール:**

| MCPツール | 用途 |
|----------|------|
| `mcp__grafana__query_prometheus` | PromQL クエリ実行 |
| `mcp__grafana__query_loki_logs` | LogQL ログクエリ実行 |
| `mcp__grafana__list_datasources` | データソース一覧取得 |
| `mcp__grafana__list_prometheus_metric_names` | メトリクス名一覧 |
| `mcp__grafana__list_prometheus_label_values` | ラベル値一覧 |
| `mcp__grafana__list_loki_label_names` | Loki ラベル名一覧 |
| `mcp__grafana__list_loki_label_values` | Loki ラベル値一覧 |

### フォールバック: curl + zsh -c

MCP サーバーが利用できない場合のみ、以下の curl 方式を使う。

**重要**: `~/.zsh_secrets` はzsh固有の構文を含むため、必ず `zsh -c` 経由で実行すること。

以下の環境変数が `~/.zshrc` / `~/.zsh_secrets` で定義済み:

| 環境変数 | 用途 |
|---------|------|
| `GRAFANA_LOKI_URL` | Loki push URL |
| `GRAFANA_LOKI_USER` | Loki Basic認証ユーザーID |
| `GRAFANA_PROMETHEUS_URL` | Prometheus push URL |
| `GRAFANA_PROMETHEUS_USER` | Prometheus Basic認証ユーザーID |
| `GRAFANA_CLOUD_API_KEY` | APIキー（`~/.zsh_secrets` に定義） |

エンドポイント導出:
- **Loki**: push URL から `/loki/api/v1/push` を除去 → + `/loki/api/v1/query_range`
- **Prometheus**: push URL から `/api/prom/push` を除去 → + `/api/prom/api/v1/query`

## データ構造

### Prometheus メトリクス

| メトリクス名 | 説明 | 主要ラベル |
|-------------|------|-----------|
| `claude_code_cost_usage_USD_total` | コスト（USD） | `model`, `pc_type` |
| `claude_code_token_usage_tokens_total` | トークン数 | `model`, `type`, `pc_type` |
| `claude_code_active_time_seconds_total` | アクティブ時間 | `pc_type` |
| `claude_code_session_count_total` | セッション数 | `pc_type` |
| `claude_code_commit_count_total` | コミット数 | `pc_type` |
| `claude_code_lines_of_code_count_total` | コード行数 | `pc_type` |
| `claude_code_code_edit_tool_decision_total` | 編集ツール決定数 | `pc_type` |

**トークン `type` ラベル値**: `input`, `output`, `cacheRead`, `cacheCreation`

### Loki ログ

**job="claude-code"** (OTel経由):
- ラベル: `service_name`, `exporter=OTLP`, `detected_level` (info/error/warn), `pc_type`
- ログ本文はJSON。`| json` パイプラインで属性展開

**job="claude-hooks"** (Promtail経由):
- ラベル: `tool_name`, `subagent_type`, `skill`, `pc_type`
- ログ本文はJSON: `timestamp`, `tool_name`, `subagent_type`, `skill`, `description`, `prompt`, `args`

## PC種別の区別

OTelコレクターとPromtailで `pc_type` ラベルが自動付与される:
- `home` — 自宅PC（デフォルト）
- `work` — 会社PC（`~/.is_work_pc` が存在する環境）

**注意**: `pc_type` ラベルは2026-02-26以降のデータにのみ存在。

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
2. 以下の3クエリを MCP ツールで**並列実行**:
   - `mcp__grafana__query_prometheus` — 今日のコスト合計（PC別）
   - `mcp__grafana__query_prometheus` — 今日のトークン消費量（PC別）
   - `mcp__grafana__query_loki_logs` — 直近24hのエラー件数（PC別）
3. テーブル形式で出力

MCP が利用できない場合は `zsh -c` 経由の curl で代替する。

## 手動 `/grafana` — 詳細レポート

ユーザーが `/grafana` を実行、またはコスト・トークン・パフォーマンスについて質問した場合、**レポートスクリプトを実行**して結果をMarkdownテーブルに整形する。

### レポートスクリプト

```bash
zsh ~/.claude/skills/grafana-cloud/grafana-report.sh [home|work] [24h|7d|30d]
```

| コマンド | 動作 |
|---------|------|
| `zsh grafana-report.sh` | 全PC合計の詳細レポート（24h） |
| `zsh grafana-report.sh home` | Home PCのデータのみ |
| `zsh grafana-report.sh work` | Work PCのデータのみ |
| `zsh grafana-report.sh 7d` | 直近7日間のレポート |
| `zsh grafana-report.sh home 7d` | Home PCの直近7日間 |

スクリプトはPrometheus/Lokiクエリを**並列実行**し、TSV形式で以下を出力する:
- COST: モデル別コスト + 合計
- TOKENS: 種別内訳（input/output/cacheRead/cacheCreation）
- CACHE HIT RATE: キャッシュヒット率
- SESSION STATS: セッション数、アクティブ時間、コミット数、コード行数
- TOOL USAGE: OTelログから上位15ツール
- EVENT DISTRIBUTION: イベント種別分布
- ERRORS: 直近20件のエラー詳細（OTelの `claude_code.api_error` イベントから）
- DAILY COST TREND: 日別コスト推移

### 出力のMarkdown整形ルール

スクリプト出力のTSVデータを以下のルールでMarkdownテーブルに変換:
- 金額: `$X.XX`
- トークン: `K`/`M`単位（例: 29.1M, 1.1M, 180.8K）
- パーセンテージ: `XX.X%`
- 時間: `X.Xh`

### 追加の個別クエリが必要な場合

スクリプトで得られない情報が必要な場合は、MCPツールを直接呼び出す:

```
# Prometheus クエリ（MCP推奨）
mcp__grafana__query_prometheus(
  datasourceUid: "<uid>",
  expr: "<PROMQL>",
  startRfc3339: "2026-03-01T00:00:00+09:00",
  endRfc3339: "2026-03-01T23:59:59+09:00",
  stepSeconds: 3600
)

# Loki ログクエリ（MCP推奨）
mcp__grafana__query_loki_logs(
  datasourceUid: "<uid>",
  logQL: "<LOGQL>",
  startRfc3339: "2026-03-01T00:00:00+09:00",
  endRfc3339: "2026-03-01T23:59:59+09:00",
  limit: 100
)
```

**datasourceUid** は `mcp__grafana__list_datasources` で取得する。

### フォールバック: curl テンプレート

MCP が利用できない場合のみ:

```bash
# Prometheus instant query
zsh -c 'source ~/.zshrc 2>/dev/null; source ~/.zsh_secrets 2>/dev/null; \
  PROM_BASE="${GRAFANA_PROMETHEUS_URL%/api/prom/push}" && \
  curl -s -u "$GRAFANA_PROMETHEUS_USER:$GRAFANA_CLOUD_API_KEY" \
    "$PROM_BASE/api/prom/api/v1/query" \
    --data-urlencode "query=<PROMQL>" | jq .'

# Loki query_range
zsh -c 'source ~/.zshrc 2>/dev/null; source ~/.zsh_secrets 2>/dev/null; \
  LOKI_BASE="${GRAFANA_LOKI_URL%/loki/api/v1/push}" && \
  START=$(date -u -v-24H +%Y-%m-%dT%H:%M:%SZ) && END=$(date -u +%Y-%m-%dT%H:%M:%SZ) && \
  curl -s -u "$GRAFANA_LOKI_USER:$GRAFANA_CLOUD_API_KEY" \
    "$LOKI_BASE/loki/api/v1/query_range" \
    --data-urlencode "query=<LOGQL>" \
    --data-urlencode "start=$START" --data-urlencode "end=$END" \
    --data-urlencode "limit=5000" | jq .'
```

## クエリリファレンス

詳細なクエリ定義は [references/queries.md](references/queries.md) を参照。

## 注意事項

- **MCP ツールを優先的に使う**。curl は MCP が利用できない場合のフォールバック
- curl を使う場合は **必ず `zsh -c '...'` で実行する**（bashでは `~/.zsh_secrets` のsourceが失敗する）
- Loki クエリはデフォルトで最大5000件。大量データの場合は期間を短くする
- Prometheus メトリクスは Delta→Cumulative 変換済みのため `rate()` や `increase()` が使える
- **APIキーを絶対にログや出力に含めないこと**
- `pc_type` ラベルは2026-02-26以降のデータのみ
