#!/usr/bin/env zsh
# grafana-report.sh — Claude Code 使用状況レポート生成スクリプト
# Usage: zsh grafana-report.sh [home|work] [24h|7d|30d]
set -euo pipefail

# ── 引数解析 ──────────────────────────────────────────────
PC_FILTER=""
PERIOD="24h"

for arg in "$@"; do
  case "$arg" in
    home|work) PC_FILTER="$arg" ;;
    24h|7d|30d|1w|1m)
      case "$arg" in
        24h) PERIOD="24h" ;;
        7d|1w) PERIOD="7d" ;;
        30d|1m) PERIOD="30d" ;;
      esac ;;
  esac
done

# ── 環境変数読み込み ──────────────────────────────────────
source ~/.zshrc 2>/dev/null
source ~/.zsh_secrets 2>/dev/null

PROM_BASE="${GRAFANA_PROMETHEUS_URL%/api/prom/push}"
LOKI_BASE="${GRAFANA_LOKI_URL%/loki/api/v1/push}"

# ── 時間範囲（Loki用 ISO8601） ────────────────────────────
case "$PERIOD" in
  24h) LOKI_START=$(date -u -v-24H +%Y-%m-%dT%H:%M:%SZ) ;;
  7d)  LOKI_START=$(date -u -v-7d  +%Y-%m-%dT%H:%M:%SZ) ;;
  30d) LOKI_START=$(date -u -v-30d +%Y-%m-%dT%H:%M:%SZ) ;;
esac
LOKI_END=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Prometheus range query 用（epoch秒）
case "$PERIOD" in
  24h) PROM_START=$(date -v-24H +%s) ;;
  7d)  PROM_START=$(date -v-7d  +%s) ;;
  30d) PROM_START=$(date -v-30d +%s) ;;
esac
PROM_END=$(date +%s)

# ── PromQL フィルタ構築 ───────────────────────────────────
# PC_FILTER あり → {pc_type="xxx"} でフィルタ、group by しない
# PC_FILTER なし → フィルタなし、group by pc_type を追加
# increase(metric[PERIOD]) は deltatocumulative のカウンターリセット（Docker再起動等）で
# 長期間ほど値が減る問題がある。sum_over_time(increase(metric[1d])[PERIOD:1d]) で
# 1日単位の増分を合算する方式に変更し、リセットの影響を最小化する。
if [[ -n "$PC_FILTER" ]]; then
  PCT="{pc_type=\"${PC_FILTER}\"}"
  COST_Q="sum by (model)(sum_over_time(increase(claude_code_cost_usage_USD_total${PCT}[1d])[${PERIOD}:1d]))"
  TOKEN_Q="sum by (type)(sum_over_time(increase(claude_code_token_usage_tokens_total${PCT}[1d])[${PERIOD}:1d]))"
  CACHE_Q="sum(sum_over_time(increase(claude_code_token_usage_tokens_total{type=\"cacheRead\",pc_type=\"${PC_FILTER}\"}[1d])[${PERIOD}:1d])) / (sum(sum_over_time(increase(claude_code_token_usage_tokens_total{type=\"input\",pc_type=\"${PC_FILTER}\"}[1d])[${PERIOD}:1d])) + sum(sum_over_time(increase(claude_code_token_usage_tokens_total{type=\"cacheRead\",pc_type=\"${PC_FILTER}\"}[1d])[${PERIOD}:1d])))"
  SESSION_Q="sum(sum_over_time(increase(claude_code_session_count_total${PCT}[1d])[${PERIOD}:1d]))"
  ACTIVE_Q="sum(sum_over_time(increase(claude_code_active_time_seconds_total${PCT}[1d])[${PERIOD}:1d])) / 3600"
  COMMIT_Q="sum(sum_over_time(increase(claude_code_commit_count_total${PCT}[1d])[${PERIOD}:1d]))"
  LOC_Q="sum(sum_over_time(increase(claude_code_lines_of_code_count_total${PCT}[1d])[${PERIOD}:1d]))"
  DAILY_Q="sum by (model)(increase(claude_code_cost_usage_USD_total${PCT}[1d]))"
else
  COST_Q="sum by (model)(sum_over_time(increase(claude_code_cost_usage_USD_total[1d])[${PERIOD}:1d]))"
  TOKEN_Q="sum by (type)(sum_over_time(increase(claude_code_token_usage_tokens_total[1d])[${PERIOD}:1d]))"
  CACHE_Q="sum(sum_over_time(increase(claude_code_token_usage_tokens_total{type=\"cacheRead\"}[1d])[${PERIOD}:1d])) / (sum(sum_over_time(increase(claude_code_token_usage_tokens_total{type=\"input\"}[1d])[${PERIOD}:1d])) + sum(sum_over_time(increase(claude_code_token_usage_tokens_total{type=\"cacheRead\"}[1d])[${PERIOD}:1d])))"
  SESSION_Q="sum(sum_over_time(increase(claude_code_session_count_total[1d])[${PERIOD}:1d]))"
  ACTIVE_Q="sum(sum_over_time(increase(claude_code_active_time_seconds_total[1d])[${PERIOD}:1d])) / 3600"
  COMMIT_Q="sum(sum_over_time(increase(claude_code_commit_count_total[1d])[${PERIOD}:1d]))"
  LOC_Q="sum(sum_over_time(increase(claude_code_lines_of_code_count_total[1d])[${PERIOD}:1d]))"
  DAILY_Q="sum by (model)(increase(claude_code_cost_usage_USD_total[1d]))"
fi

# ── 共通関数 ──────────────────────────────────────────────
prom_query() {
  curl -s -u "$GRAFANA_PROMETHEUS_USER:$GRAFANA_CLOUD_API_KEY" \
    "$PROM_BASE/api/prom/api/v1/query" \
    --data-urlencode "query=$1"
}

prom_range() {
  curl -s -u "$GRAFANA_PROMETHEUS_USER:$GRAFANA_CLOUD_API_KEY" \
    "$PROM_BASE/api/prom/api/v1/query_range" \
    --data-urlencode "query=$1" \
    --data-urlencode "start=$PROM_START" \
    --data-urlencode "end=$PROM_END" \
    --data-urlencode "step=${2:-86400}"
}

loki_range() {
  curl -s -u "$GRAFANA_LOKI_USER:$GRAFANA_CLOUD_API_KEY" \
    "$LOKI_BASE/loki/api/v1/query_range" \
    --data-urlencode "query=$1" \
    --data-urlencode "start=$LOKI_START" \
    --data-urlencode "end=$LOKI_END" \
    --data-urlencode "limit=${2:-5000}"
}

# ── 出力ディレクトリ（一時） ──────────────────────────────
WORK=$(mktemp -d)
trap "rm -rf $WORK" EXIT

# ── 並列クエリ実行 ────────────────────────────────────────

prom_query  "$COST_Q"    > "$WORK/cost.json" &
prom_query  "$TOKEN_Q"   > "$WORK/tokens.json" &
prom_query  "$CACHE_Q"   > "$WORK/cache_hit.json" &
prom_query  "$SESSION_Q" > "$WORK/sessions.json" &
prom_query  "$ACTIVE_Q"  > "$WORK/active_time.json" &
prom_query  "$COMMIT_Q"  > "$WORK/commits.json" &
prom_query  "$LOC_Q"     > "$WORK/loc.json" &
prom_range  "$DAILY_Q"   > "$WORK/cost_daily.json" &
loki_range  '{job="claude-code"}' 5000 > "$WORK/otel_logs.json" &
loki_range  '{job="claude-hooks"}' 5000 > "$WORK/hooks_logs.json" &

wait

# ── 結果を構造化出力 ──────────────────────────────────────

echo "=== GRAFANA REPORT (period=${PERIOD}, filter=${PC_FILTER:-all}) ==="
echo ""

# --- コスト ---
echo "--- COST ---"
jq -r '.data.result[] | "\(.metric.model // "unknown")\t\(.value[1])"' \
  "$WORK/cost.json" 2>/dev/null || echo "(no data)"
TOTAL_COST=$(jq -r '[.data.result[].value[1] | tonumber] | add // 0' "$WORK/cost.json" 2>/dev/null || echo "0")
echo "TOTAL\t${TOTAL_COST}"
echo ""

# --- トークン ---
echo "--- TOKENS ---"
jq -r '.data.result[] | "\(.metric.type)\t\(.value[1])"' \
  "$WORK/tokens.json" 2>/dev/null || echo "(no data)"
echo ""

# --- キャッシュヒット率 ---
echo "--- CACHE HIT RATE ---"
jq -r '.data.result[0].value[1] // "N/A"' \
  "$WORK/cache_hit.json" 2>/dev/null || echo "N/A"
echo ""

# --- セッション統計 ---
echo "--- SESSION STATS ---"
echo "sessions\t$(jq -r '.data.result[0].value[1] // "0"' "$WORK/sessions.json" 2>/dev/null || echo "0")"
echo "active_hours\t$(jq -r '.data.result[0].value[1] // "0"' "$WORK/active_time.json" 2>/dev/null || echo "0")"
echo "commits\t$(jq -r '.data.result[0].value[1] // "0"' "$WORK/commits.json" 2>/dev/null || echo "0")"
echo "loc\t$(jq -r '.data.result[0].value[1] // "0"' "$WORK/loc.json" 2>/dev/null || echo "0")"
echo ""

# --- ツール使用（OTelから集計） ---
echo "--- TOOL USAGE (top 15) ---"
jq -r '
  [.data.result[].values[][1] | fromjson
   | select(.body=="claude_code.tool_decision")
   | .attributes.tool_name]
  | group_by(.) | map({tool: .[0], count: length})
  | sort_by(-.count) | .[:15]
  | .[] | "\(.tool)\t\(.count)"
' "$WORK/otel_logs.json" 2>/dev/null || echo "(no data)"
echo ""

# --- Subagent使用（hooks: job="claude-hooks", tool_name="Task"） ---
echo "--- SUBAGENT USAGE (hooks) ---"
jq -r '
  [.data.result[]
   | select(.stream.tool_name=="Task")
   | {type: .stream.subagent_type, count: (.values | length)}]
  | group_by(.type) | map({type: .[0].type, count: (map(.count) | add)})
  | sort_by(-.count)
  | .[] | "\(.type)\t\(.count)"
' "$WORK/hooks_logs.json" 2>/dev/null || echo "(no data)"
echo ""

# --- Skill使用（hooks: job="claude-hooks", tool_name="Skill"） ---
echo "--- SKILL USAGE (hooks) ---"
jq -r '
  [.data.result[]
   | select(.stream.tool_name=="Skill")
   | {skill: .stream.skill, count: (.values | length)}]
  | group_by(.skill) | map({skill: .[0].skill, count: (map(.count) | add)})
  | sort_by(-.count)
  | .[] | "\(.skill)\t\(.count)"
' "$WORK/hooks_logs.json" 2>/dev/null || echo "(no data)"
echo ""

# --- Hooks全体（tool_name別） ---
echo "--- HOOKS TOOL DISTRIBUTION ---"
jq -r '
  [.data.result[]
   | {tool: (.stream.tool_name // "unknown"), count: (.values | length)}]
  | group_by(.tool) | map({tool: .[0].tool, count: (map(.count) | add)})
  | sort_by(-.count)
  | .[] | "\(.tool)\t\(.count)"
' "$WORK/hooks_logs.json" 2>/dev/null || echo "(no data)"
echo ""

# --- イベント分布 ---
echo "--- EVENT DISTRIBUTION ---"
jq -r '
  [.data.result[].values[][1] | fromjson | .body]
  | group_by(.) | map({event: .[0], count: length})
  | sort_by(-.count)
  | .[] | "\(.event)\t\(.count)"
' "$WORK/otel_logs.json" 2>/dev/null || echo "(no data)"
echo ""

# --- エラー一覧（OTelの api_error イベントから） ---
echo "--- ERRORS (recent 20) ---"
jq -r '
  [.data.result[].values[][1] | fromjson
   | select(.body=="claude_code.api_error")
   | {
       time: .attributes["event.timestamp"],
       error: (.attributes.error // .body),
       model: (.attributes.model // "n/a"),
       status: (.attributes.status_code // "n/a"),
       pc: (.resources.pc_type // "unknown")
     }]
  | sort_by(.time) | reverse | .[:20]
  | .[] | "\(.time)\t\(.pc)\t\(.model)\t\(.status)\t\(.error[:80])"
' "$WORK/otel_logs.json" 2>/dev/null || echo "(no errors)"
echo ""

# --- 日別コスト推移 ---
echo "--- DAILY COST TREND ---"
jq -r '
  .data.result[] |
  .metric.model as $model |
  .values[] | "\(.[0] | strftime("%Y-%m-%d"))\t\($model)\t\(.[1])"
' "$WORK/cost_daily.json" 2>/dev/null || echo "(no data)"
echo ""

echo "=== END ==="
