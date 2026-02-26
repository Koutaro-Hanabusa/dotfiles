---
name: grafana-cloud
description: >
  Query Grafana Cloud for Claude Code usage analytics. Triggers at session start
  to show a brief usage summary, and when user asks about costs, tokens, tool usage,
  errors, or performance. Manually invoke with /grafana.
---

# Grafana Cloud Usage Analytics

Claude CodeのOTelメトリクス・ログをGrafana Cloudから取得し、使用状況を分析するスキル。

## 認証・接続

**重要**: `~/.zsh_secrets` はzsh固有の構文を含むため、必ず `zsh -c` 経由で実行すること。

以下の環境変数が `~/.zshrc` / `~/.zsh_secrets` で定義済み:

| 環境変数 | 用途 |
|---------|------|
| `GRAFANA_LOKI_URL` | Loki push URL（queryは `/loki/api/v1/query` 等を使う） |
| `GRAFANA_LOKI_USER` | Loki Basic認証ユーザーID |
| `GRAFANA_PROMETHEUS_URL` | Prometheus push URL（queryは `/api/prom/api/v1/query` 等を使う） |
| `GRAFANA_PROMETHEUS_USER` | Prometheus Basic認証ユーザーID |
| `GRAFANA_CLOUD_API_KEY` | APIキー（`~/.zsh_secrets` に定義） |

### エンドポイントの導出

push URLからquery URLを導出する:
- **Loki**: push URL から `/loki/api/v1/push` を除いたベースURL + `/loki/api/v1/query` or `/loki/api/v1/query_range`
- **Prometheus**: push URL から `/api/prom/push` を除いたベースURL + `/api/prom/api/v1/query` or `/api/prom/api/v1/query_range`

```bash
# 例: query用ベースURLの導出
LOKI_BASE="${GRAFANA_LOKI_URL%/loki/api/v1/push}"
PROM_BASE="${GRAFANA_PROMETHEUS_URL%/api/prom/push}"
```

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
2. 以下の3クエリを `zsh -c` 経由で**並列実行**:
   - 今日のコスト合計（PC別）
   - 今日のトークン消費量（PC別）
   - 直近24hのエラー件数（PC別）
3. テーブル形式で出力

## 手動 `/grafana` — 詳細レポート

ユーザーが `/grafana` を実行、またはコスト・トークン・パフォーマンスについて質問した場合、以下の詳細レポートを生成する。

### レポート項目

1. **コスト分析**: 今日/今週/今月の合計（PC別）、モデル別内訳、日別推移
2. **トークン分析**: 種別内訳 (`input`/`output`/`cacheRead`/`cacheCreation`)、PC別
3. **ツール使用**: OTelログから集計、上位10ツール
4. **Subagent/Skill使用状況**: hooksログから `subagent_type`別 / `skill`別 / PC別
5. **キャッシュヒット率**: `cacheRead / (input + cacheRead)`、PC別比較
6. **セッション統計**: セッション数、アクティブ時間、コミット数
7. **エラー一覧**: 直近24hの `detected_level="error"` ログ、PC別

### 出力フォーマット

- Markdownテーブル
- 金額: `$X.XX`、トークン: `K`/`M`単位、パーセンテージ: `XX.X%`
- PC種別は Home / Work で区別

## API呼び出しテンプレート

### Prometheus instant query

```bash
zsh -c 'source ~/.zsh_secrets && \
  PROM_BASE="${GRAFANA_PROMETHEUS_URL%/api/prom/push}" && \
  curl -s -u "$GRAFANA_PROMETHEUS_USER:$GRAFANA_CLOUD_API_KEY" \
    "$PROM_BASE/api/prom/api/v1/query" \
    --data-urlencode "query=<PROMQL>" | jq .'
```

### Prometheus range query

```bash
zsh -c 'source ~/.zsh_secrets && \
  PROM_BASE="${GRAFANA_PROMETHEUS_URL%/api/prom/push}" && \
  START=$(date -v-7d +%s) && END=$(date +%s) && \
  curl -s -u "$GRAFANA_PROMETHEUS_USER:$GRAFANA_CLOUD_API_KEY" \
    "$PROM_BASE/api/prom/api/v1/query_range" \
    --data-urlencode "query=<PROMQL>" \
    --data-urlencode "start=$START" --data-urlencode "end=$END" \
    --data-urlencode "step=86400" | jq .'
```

### Loki instant query

```bash
zsh -c 'source ~/.zsh_secrets && \
  LOKI_BASE="${GRAFANA_LOKI_URL%/loki/api/v1/push}" && \
  curl -s -u "$GRAFANA_LOKI_USER:$GRAFANA_CLOUD_API_KEY" \
    "$LOKI_BASE/loki/api/v1/query" \
    --data-urlencode "query=<LOGQL>" | jq .'
```

### Loki query_range

```bash
zsh -c 'source ~/.zsh_secrets && \
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

- **必ず `zsh -c '...'` で実行する**（bashでは `~/.zsh_secrets` のsourceが失敗する）
- Loki の `query_range` はデフォルトで最大5000件。大量データの場合は期間を短くする
- Prometheus メトリクスは Delta→Cumulative 変換済みのため `rate()` や `increase()` が使える
- **APIキーを絶対にログや出力に含めないこと**
- `pc_type` ラベルは2026-02-26以降のデータのみ
