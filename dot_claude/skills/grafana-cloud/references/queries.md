# Grafana Cloud クエリリファレンス

Claude CodeのOTelデータを照会するためのLoki (LogQL) / Prometheus (PromQL) クエリ集。

## 共通パラメータ

- `<START>`: RFC3339形式 (Loki) or UNIXタイムスタンプ (Prometheus)
- `<END>`: 同上
- `<RANGE>`: 期間指定 (`1h`, `24h`, `7d`, `30d`)
- PC種別フィルタ: `pc_type="home"` または `pc_type="work"`

---

## 1. コスト分析

### 今日のコスト合計

```promql
sum(claude_code_cost_usage_USD_total)
```

### PC別コスト合計

```promql
sum by (pc_type)(claude_code_cost_usage_USD_total)
```

### モデル別コスト

```promql
sum by (model)(claude_code_cost_usage_USD_total)
```

### モデル別 x PC別コスト

```promql
sum by (model, pc_type)(claude_code_cost_usage_USD_total)
```

### 日別コスト推移（range query, step=86400）

```promql
sum(claude_code_cost_usage_USD_total)
```

---

## 2. トークン分析

### トークン種別合計

```promql
# Input tokens
sum(claude_code_token_usage_input_tokens_total)

# Output tokens
sum(claude_code_token_usage_output_tokens_total)

# Cache read tokens
sum(claude_code_token_usage_cache_read_input_tokens_total)

# Cache creation tokens
sum(claude_code_token_usage_cache_creation_input_tokens_total)
```

### PC別トークン

```promql
sum by (pc_type)(claude_code_token_usage_input_tokens_total)
sum by (pc_type)(claude_code_token_usage_output_tokens_total)
sum by (pc_type)(claude_code_token_usage_cache_read_input_tokens_total)
sum by (pc_type)(claude_code_token_usage_cache_creation_input_tokens_total)
```

### キャッシュヒット率

```promql
sum(claude_code_token_usage_cache_read_input_tokens_total)
/
(sum(claude_code_token_usage_input_tokens_total) + sum(claude_code_token_usage_cache_read_input_tokens_total))
```

### PC別キャッシュヒット率

```promql
sum by (pc_type)(claude_code_token_usage_cache_read_input_tokens_total)
/
(sum by (pc_type)(claude_code_token_usage_input_tokens_total) + sum by (pc_type)(claude_code_token_usage_cache_read_input_tokens_total))
```

---

## 3. ツール使用分析（Loki）

### ツール呼び出し回数ランキング

```logql
sum by (attributes_tool_name)(
  count_over_time(
    {job="claude-code"} |= "tool_result" | json [<RANGE>]
  )
)
```

### PC別ツール呼び出し

```logql
sum by (attributes_tool_name, pc_type)(
  count_over_time(
    {job="claude-code"} |= "tool_result" | json [<RANGE>]
  )
)
```

---

## 4. Subagent / Skill 分析（Loki — claude-hooks）

### Subagent種別ごとの呼び出し回数

```logql
sum by (subagent_type)(
  count_over_time(
    {job="claude-hooks", tool_name="Task"} [<RANGE>]
  )
)
```

### PC別 Subagent使用状況

```logql
sum by (subagent_type, pc_type)(
  count_over_time(
    {job="claude-hooks", tool_name="Task"} [<RANGE>]
  )
)
```

### Skill呼び出し回数

```logql
sum by (skill)(
  count_over_time(
    {job="claude-hooks", tool_name="Skill"} [<RANGE>]
  )
)
```

### PC別 Skill使用状況

```logql
sum by (skill, pc_type)(
  count_over_time(
    {job="claude-hooks", tool_name="Skill"} [<RANGE>]
  )
)
```

---

## 5. APIパフォーマンス（Loki）

### レスポンスタイム p50

```logql
quantile_over_time(0.5,
  {job="claude-code"} |= "api_request" | json | unwrap attributes_duration_ms [<RANGE>]
) by ()
```

### レスポンスタイム p95

```logql
quantile_over_time(0.95,
  {job="claude-code"} |= "api_request" | json | unwrap attributes_duration_ms [<RANGE>]
) by ()
```

### PC別レスポンスタイム

```logql
quantile_over_time(0.5,
  {job="claude-code"} |= "api_request" | json | unwrap attributes_duration_ms [<RANGE>]
) by (pc_type)
```

---

## 6. エラー分析（Loki）

### APIエラー一覧（直近24h）

```logql
{job="claude-code"} |= "api_error" | json
```

### エラー件数（PC別）

```logql
sum by (pc_type)(
  count_over_time(
    {job="claude-code"} |= "api_error" | json [<RANGE>]
  )
)
```

### ツール実行失敗

```logql
{job="claude-code"} |= "tool_result" | json | attributes_is_error = "true"
```

---

## 7. Prometheus メトリクス一覧

Claude Codeが送信する主要メトリクス:

| メトリクス名 | 説明 | ラベル |
|-------------|------|--------|
| `claude_code_cost_usage_USD_total` | コスト（USD） | `model`, `pc_type` |
| `claude_code_token_usage_input_tokens_total` | 入力トークン | `model`, `pc_type` |
| `claude_code_token_usage_output_tokens_total` | 出力トークン | `model`, `pc_type` |
| `claude_code_token_usage_cache_read_input_tokens_total` | キャッシュ読取トークン | `model`, `pc_type` |
| `claude_code_token_usage_cache_creation_input_tokens_total` | キャッシュ作成トークン | `model`, `pc_type` |

### メトリクス名の確認

実際のメトリクス名は以下のクエリで確認可能:

```promql
{__name__=~"claude.*"}
```

---

## 8. curl実行例

### Loki query_range

```bash
source ~/.zsh_secrets
START=$(date -u -v-24H +%Y-%m-%dT%H:%M:%SZ)  # 24時間前
END=$(date -u +%Y-%m-%dT%H:%M:%SZ)             # 現在

curl -s -u "1497154:$GRAFANA_CLOUD_API_KEY" \
  "https://logs-prod-030.grafana.net/loki/api/v1/query_range" \
  --data-urlencode "query={job=\"claude-code\"} |= \"api_request\" | json" \
  --data-urlencode "start=$START" \
  --data-urlencode "end=$END" \
  --data-urlencode "limit=5000" | jq .
```

### Loki instant query

```bash
source ~/.zsh_secrets
curl -s -u "1497154:$GRAFANA_CLOUD_API_KEY" \
  "https://logs-prod-030.grafana.net/loki/api/v1/query" \
  --data-urlencode "query=sum by (subagent_type)(count_over_time({job=\"claude-hooks\", tool_name=\"Task\"} [24h]))" | jq .
```

### Prometheus instant query

```bash
source ~/.zsh_secrets
curl -s -u "3002958:$GRAFANA_CLOUD_API_KEY" \
  "https://prometheus-prod-49-prod-ap-northeast-0.grafana.net/api/prom/api/v1/query" \
  --data-urlencode "query=sum by (pc_type)(claude_code_cost_usage_USD_total)" | jq .
```

### Prometheus range query

```bash
source ~/.zsh_secrets
START=$(date -v-7d +%s)  # 7日前
END=$(date +%s)           # 現在

curl -s -u "3002958:$GRAFANA_CLOUD_API_KEY" \
  "https://prometheus-prod-49-prod-ap-northeast-0.grafana.net/api/prom/api/v1/query_range" \
  --data-urlencode "query=sum(claude_code_cost_usage_USD_total)" \
  --data-urlencode "start=$START" \
  --data-urlencode "end=$END" \
  --data-urlencode "step=86400" | jq .
```
