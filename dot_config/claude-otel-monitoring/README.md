# Claude Code OpenTelemetry モニタリング環境 (Grafana Cloud)

Claude Code の OpenTelemetry メトリクス・ログを Grafana Cloud に送信する構成です。

## 構成

- **OTel Collector** (0.120.0): gRPC/HTTP でテレメトリデータを受信 → Grafana Cloud に転送
- **Promtail** (2.9.4): Hooks ログを Grafana Cloud Loki に送信

## 前提条件

### 環境変数（`~/.zshrc` に設定済み）

```bash
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
```

### APIキー（`~/.zsh_secrets` に設定）

```bash
export GRAFANA_CLOUD_API_KEY="glc_..."
```

## 起動

```bash
cd ~/.config/claude-otel-monitoring
./manage.sh start
```

## 停止

```bash
./manage.sh stop
```

## アクセス

- **Grafana Cloud ダッシュボード**: https://grafana.com にログイン
- **OTel Collector**:
  - gRPC: `localhost:4317`
  - HTTP: `localhost:4318`
  - メトリクス: http://localhost:8888/metrics

## トラブルシューティング

### OTel Collector がデータを送信しない

```bash
# Collector のログを確認
./manage.sh logs otel-collector

# 環境変数を確認
echo $GRAFANA_CLOUD_API_KEY
echo $OTEL_EXPORTER_OTLP_ENDPOINT
```

### Grafana Cloud にメトリクスが表示されない

1. API キーの権限を確認（MetricsPublisher + LogsPublisher が必要）
2. OTel Collector ログで認証エラーがないか確認
3. `curl -sf http://localhost:8888/metrics` でCollectorが稼働しているか確認

## ダッシュボード

`dashboard-backup/claude-code.json` にダッシュボードJSONのバックアップがあります。
Grafana Cloud の Import 機能でインポートできます。
