# Grafana Cloud クエリリファレンス

実際のメトリクス名・ラベル構造に基づくPromQL / LogQLクエリ集（2026-02-26検証済み）。

API呼び出しテンプレートは [SKILL.md](../SKILL.md) を参照。

---

## 1. コスト分析 (PromQL)

```promql
# 合計
sum(claude_code_cost_usage_USD_total)

# PC別
sum by (pc_type)(claude_code_cost_usage_USD_total)

# モデル別
sum by (model)(claude_code_cost_usage_USD_total)

# モデル別 x PC別
sum by (model, pc_type)(claude_code_cost_usage_USD_total)
```

日別推移は range query (step=86400) で取得。

---

## 2. トークン分析 (PromQL)

`type` ラベル: `input`, `output`, `cacheRead`, `cacheCreation`

```promql
# 種別ごと合計
sum by (type)(claude_code_token_usage_tokens_total)

# PC別 x 種別
sum by (type, pc_type)(claude_code_token_usage_tokens_total)

# モデル別 x 種別
sum by (model, type)(claude_code_token_usage_tokens_total)
```

### キャッシュヒット率

```promql
# 全体
sum(claude_code_token_usage_tokens_total{type="cacheRead"})
/
(sum(claude_code_token_usage_tokens_total{type="input"}) + sum(claude_code_token_usage_tokens_total{type="cacheRead"}))

# PC別
sum by (pc_type)(claude_code_token_usage_tokens_total{type="cacheRead"})
/
(sum by (pc_type)(claude_code_token_usage_tokens_total{type="input"}) + sum by (pc_type)(claude_code_token_usage_tokens_total{type="cacheRead"}))
```

---

## 3. セッション統計 (PromQL)

```promql
sum(claude_code_session_count_total)
sum by (pc_type)(claude_code_session_count_total)

# アクティブ時間（時間単位）
sum(claude_code_active_time_seconds_total) / 3600
sum by (pc_type)(claude_code_active_time_seconds_total) / 3600

# コミット数
sum(claude_code_commit_count_total)
sum by (pc_type)(claude_code_commit_count_total)

# コード行数
sum(claude_code_lines_of_code_count_total)
sum by (pc_type)(claude_code_lines_of_code_count_total)
```

---

## 4. Subagent / Skill 分析 (LogQL)

```logql
# Subagent種別ごとの呼び出し回数
sum by (subagent_type)(count_over_time({job="claude-hooks", tool_name="Task"} [24h]))

# PC別 Subagent
sum by (subagent_type, pc_type)(count_over_time({job="claude-hooks", tool_name="Task"} [24h]))

# Skill呼び出し回数
sum by (skill)(count_over_time({job="claude-hooks", tool_name="Skill"} [24h]))

# PC別 Skill
sum by (skill, pc_type)(count_over_time({job="claude-hooks", tool_name="Skill"} [24h]))

# Hooks全体
sum by (tool_name)(count_over_time({job="claude-hooks"} [24h]))
```

---

## 5. エラー分析 (LogQL)

```logql
# エラーログ一覧
{job="claude-code", detected_level="error"}

# エラー件数
count_over_time({job="claude-code", detected_level="error"} [24h])

# PC別エラー件数
sum by (pc_type)(count_over_time({job="claude-code", detected_level="error"} [24h]))
```

---

## 6. OTelログ (LogQL)

```logql
# ログ本文JSON展開
{job="claude-code"} | json

# 特定イベント検索
{job="claude-code"} |= "検索文字列" | json
```

ラベル: `job`, `service_name`, `exporter`, `detected_level`, `pc_type`

---

## 7. よくある分析パターン

### 今日のサマリー（並列3クエリ）

1. コスト: `sum by (pc_type)(claude_code_cost_usage_USD_total)`
2. トークン: `sum by (pc_type)(claude_code_token_usage_tokens_total)`
3. エラー: `sum by (pc_type)(count_over_time({job="claude-code", detected_level="error"} [24h]))`

### PC間の使用量比較

```promql
sum by (pc_type)(claude_code_cost_usage_USD_total)
```

```logql
sum by (pc_type)(count_over_time({job="claude-hooks"} [7d]))
```
