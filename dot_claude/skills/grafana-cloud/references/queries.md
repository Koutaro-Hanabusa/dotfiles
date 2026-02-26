# Grafana Cloud クエリリファレンス

Claude CodeのOTelデータを照会するためのPromQL / LogQLクエリ集。
実際のメトリクス名・ラベル構造に基づく（2026-02-26時点で検証済み）。

## 共通事項

- **認証**: 必ず `zsh -c 'source ~/.zsh_secrets && ...'` 経由で実行
- **Prometheus ユーザー**: `3002958`
- **Loki ユーザー**: `1497154`
- **PC種別ラベル**: `pc_type` — `home` or `work`（2026-02-26以降のデータのみ）

---

## 1. コスト分析 (Prometheus)

### コスト合計

```promql
sum(claude_code_cost_usage_USD_total)
```

### PC別コスト

```promql
sum by (pc_type)(claude_code_cost_usage_USD_total)
```

### モデル別コスト

```promql
sum by (model)(claude_code_cost_usage_USD_total)
```

### モデル別 x PC別

```promql
sum by (model, pc_type)(claude_code_cost_usage_USD_total)
```

### 日別コスト推移（range query, step=86400）

```promql
sum(claude_code_cost_usage_USD_total)
```

---

## 2. トークン分析 (Prometheus)

メトリクス: `claude_code_token_usage_tokens_total`
`type` ラベルでトークン種別を区別: `input`, `output`, `cacheRead`, `cacheCreation`

### 種別ごとの合計

```promql
sum by (type)(claude_code_token_usage_tokens_total)
```

### PC別 x 種別

```promql
sum by (type, pc_type)(claude_code_token_usage_tokens_total)
```

### モデル別 x 種別

```promql
sum by (model, type)(claude_code_token_usage_tokens_total)
```

### キャッシュヒット率

```promql
sum(claude_code_token_usage_tokens_total{type="cacheRead"})
/
(sum(claude_code_token_usage_tokens_total{type="input"}) + sum(claude_code_token_usage_tokens_total{type="cacheRead"}))
```

### PC別キャッシュヒット率

```promql
sum by (pc_type)(claude_code_token_usage_tokens_total{type="cacheRead"})
/
(sum by (pc_type)(claude_code_token_usage_tokens_total{type="input"}) + sum by (pc_type)(claude_code_token_usage_tokens_total{type="cacheRead"}))
```

---

## 3. セッション統計 (Prometheus)

### セッション数

```promql
sum(claude_code_session_count_total)
sum by (pc_type)(claude_code_session_count_total)
```

### アクティブ時間（秒→時間）

```promql
sum(claude_code_active_time_seconds_total) / 3600
sum by (pc_type)(claude_code_active_time_seconds_total) / 3600
```

### コミット数

```promql
sum(claude_code_commit_count_total)
sum by (pc_type)(claude_code_commit_count_total)
```

### コード行数

```promql
sum(claude_code_lines_of_code_count_total)
sum by (pc_type)(claude_code_lines_of_code_count_total)
```

---

## 4. Subagent / Skill 分析 (Loki — claude-hooks)

### Subagent種別ごとの呼び出し回数

```logql
sum by (subagent_type)(count_over_time({job="claude-hooks", tool_name="Task"} [24h]))
```

### PC別 Subagent使用状況

```logql
sum by (subagent_type, pc_type)(count_over_time({job="claude-hooks", tool_name="Task"} [24h]))
```

### Skill呼び出し回数

```logql
sum by (skill)(count_over_time({job="claude-hooks", tool_name="Skill"} [24h]))
```

### PC別 Skill使用状況

```logql
sum by (skill, pc_type)(count_over_time({job="claude-hooks", tool_name="Skill"} [24h]))
```

### Hooks全体の呼び出し回数

```logql
sum by (tool_name)(count_over_time({job="claude-hooks"} [24h]))
```

---

## 5. エラー分析 (Loki)

### エラーログ一覧（直近24h）

```logql
{job="claude-code", detected_level="error"}
```

### エラー件数

```logql
count_over_time({job="claude-code", detected_level="error"} [24h])
```

### PC別エラー件数

```logql
sum by (pc_type)(count_over_time({job="claude-code", detected_level="error"} [24h]))
```

---

## 6. OTelログ詳細分析 (Loki — claude-code)

### ログラベル構造

```
job="claude-code"
service_name="claude-code"
exporter="OTLP"
detected_level="info" | "error" | "warn"
pc_type="home" | "work"  (2026-02-26以降)
```

### ログ本文JSON展開

```logql
{job="claude-code"} | json
```

### 特定イベントの検索

```logql
{job="claude-code"} |= "検索文字列" | json
```

---

## 7. curl実行テンプレート

### Prometheus instant query

```bash
zsh -c 'source ~/.zsh_secrets && curl -s -u "3002958:$GRAFANA_CLOUD_API_KEY" \
  "https://prometheus-prod-49-prod-ap-northeast-0.grafana.net/api/prom/api/v1/query" \
  --data-urlencode "query=<PROMQL_HERE>" | jq .'
```

### Prometheus range query

```bash
zsh -c 'source ~/.zsh_secrets && \
  START=$(date -v-7d +%s) && \
  END=$(date +%s) && \
  curl -s -u "3002958:$GRAFANA_CLOUD_API_KEY" \
    "https://prometheus-prod-49-prod-ap-northeast-0.grafana.net/api/prom/api/v1/query_range" \
    --data-urlencode "query=<PROMQL_HERE>" \
    --data-urlencode "start=$START" \
    --data-urlencode "end=$END" \
    --data-urlencode "step=86400" | jq .'
```

### Loki instant query

```bash
zsh -c 'source ~/.zsh_secrets && curl -s -u "1497154:$GRAFANA_CLOUD_API_KEY" \
  "https://logs-prod-030.grafana.net/loki/api/v1/query" \
  --data-urlencode "query=<LOGQL_HERE>" | jq .'
```

### Loki query_range

```bash
zsh -c 'source ~/.zsh_secrets && \
  START=$(date -u -v-24H +%Y-%m-%dT%H:%M:%SZ) && \
  END=$(date -u +%Y-%m-%dT%H:%M:%SZ) && \
  curl -s -u "1497154:$GRAFANA_CLOUD_API_KEY" \
    "https://logs-prod-030.grafana.net/loki/api/v1/query_range" \
    --data-urlencode "query=<LOGQL_HERE>" \
    --data-urlencode "start=$START" \
    --data-urlencode "end=$END" \
    --data-urlencode "limit=5000" | jq .'
```

---

## 8. よくある分析パターン

### 今日のサマリー（全指標一括取得）

並列で3つのクエリを実行:

1. **コスト**: `sum by (pc_type)(claude_code_cost_usage_USD_total)`
2. **トークン**: `sum by (pc_type)(claude_code_token_usage_tokens_total)`
3. **エラー**: `sum by (pc_type)(count_over_time({job="claude-code", detected_level="error"} [24h]))`

### 週次レポート

range queryで7日分:
- step=86400 (1日単位)
- `sum(claude_code_cost_usage_USD_total)` のrange query

### PC間の使用量比較

```promql
# Home vs Work コスト比較
sum by (pc_type)(claude_code_cost_usage_USD_total)
```

```logql
# Home vs Work subagent使用比較
sum by (pc_type)(count_over_time({job="claude-hooks"} [7d]))
```
