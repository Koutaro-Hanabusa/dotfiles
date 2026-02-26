# Claude Code OpenTelemetry モニタリング環境

Claude Code の OpenTelemetry メトリクス・ログを収集し可視化するための完全な監視スタックです。

## 構成

- **OTel Collector** (0.96.0): gRPC/HTTP でテレメトリデータを受信
- **Loki** (2.9.4): ログの保存と検索
- **Prometheus** (2.49.1): メトリクスの保存とクエリ
- **Grafana** (10.3.3): データの可視化とダッシュボード

## 前提条件

以下の環境変数が `~/.zshrc` に設定されていること:

```bash
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
```

## 起動

```bash
cd ~/.config/claude-otel-monitoring
docker compose up -d
```

## 停止

```bash
cd ~/.config/claude-otel-monitoring
docker compose down
```

## データを削除して再起動

```bash
cd ~/.config/claude-otel-monitoring
docker compose down -v
docker compose up -d
```

## アクセス

- **Grafana**: http://localhost:3030
  - 認証不要(匿名アクセス有効)
  - Claude Code ダッシュボードが自動プロビジョニング済み

- **Prometheus**: http://localhost:9090
  - メトリクスの直接クエリが可能

- **Loki**: http://localhost:3100
  - LogQL でログクエリ可能

- **OTel Collector**:
  - gRPC: `localhost:4317`
  - HTTP: `localhost:4318`
  - メトリクス: http://localhost:8888/metrics

## ダッシュボード

Grafana の Claude Code ダッシュボードには以下のパネルが含まれています:

### メトリクス
- **Token Usage Rate**: トークン使用量の推移
- **Total Tokens (Last Hour)**: 直近1時間のトークン総数
- **Tool Call Rate by Tool**: ツール別の呼び出し頻度
- **Tool Usage Distribution**: ツール使用の割合
- **Session Duration**: セッション継続時間
- **Error Rate**: エラー発生率
- **Total Requests**: リクエスト総数
- **Total Errors**: エラー総数
- **Total Tool Calls**: ツール呼び出し総数
- **Average Response Time**: 平均応答時間

### ログ
- **Claude Code Logs**: リアルタイムログストリーム

## コンテナログの確認

```bash
# 全コンテナのログ
docker compose logs -f

# 特定のコンテナのログ
docker compose logs -f otel-collector
docker compose logs -f loki
docker compose logs -f prometheus
docker compose logs -f grafana
```

## トラブルシューティング

### OTel Collector がデータを受信しない

```bash
# Collector のログを確認
docker compose logs -f otel-collector

# 環境変数を確認
echo $OTEL_EXPORTER_OTLP_ENDPOINT
```

### Grafana でデータソースが接続できない

```bash
# Prometheus の健全性確認
curl http://localhost:9090/-/healthy

# Loki の準備状態確認
curl http://localhost:3100/ready
```

### ポート競合

デフォルトのポート設定:
- `3030`: Grafana (変更済み、元は3000)
- `3100`: Loki
- `4317`: OTel Collector gRPC
- `4318`: OTel Collector HTTP
- `8888`: OTel Collector メトリクス
- `9090`: Prometheus

ポート変更は `docker-compose.yml` の `ports` セクションを編集してください。

## カスタマイズ

### メトリクスの保持期間を変更

`prometheus.yml` に以下を追加:

```yaml
global:
  storage.tsdb.retention.time: 30d  # デフォルトは15d
```

### ログの保持期間を変更

`loki-config.yaml` の `limits_config` セクションを編集:

```yaml
limits_config:
  retention_period: 720h  # 30日
```

### ダッシュボードのカスタマイズ

Grafana UI で直接編集するか、`grafana/provisioning/dashboards/claude-code.json` を編集してコンテナを再起動してください。

## データの永続化

以下の Docker volumes でデータが永続化されます:

- `prometheus-data`: Prometheus のメトリクスデータ
- `loki-data`: Loki のログデータ
- `grafana-data`: Grafana の設定とダッシュボード

## ネットワーク

全てのコンテナは `claude-monitoring` という専用ネットワークで通信します。

## 注意事項

- このセットアップはローカル開発用です
- Grafana は匿名アクセスが有効になっています(Admin権限)
- 本番環境では適切な認証・認可を設定してください
- Claude Code が送信する実際のメトリクス名は予測値です。実際の名前に合わせてクエリを調整してください
