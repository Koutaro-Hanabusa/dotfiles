#!/bin/bash

# Claude Code OTel Monitoring Stack Management Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

case "${1:-}" in
  start|up)
    echo "Starting Claude Code monitoring stack..."
    docker compose up -d
    echo ""
    echo "✓ All services are running"
    echo ""
    echo "Access URLs:"
    echo "  Grafana:    http://localhost:3030"
    echo "  Prometheus: http://localhost:9090"
    echo "  Loki:       http://localhost:3100"
    echo ""
    ;;

  stop|down)
    echo "Stopping Claude Code monitoring stack..."
    docker compose down
    echo "✓ All services stopped"
    ;;

  restart)
    echo "Restarting Claude Code monitoring stack..."
    docker compose restart
    echo "✓ All services restarted"
    ;;

  status|ps)
    docker compose ps
    ;;

  logs)
    SERVICE="${2:-}"
    if [ -z "$SERVICE" ]; then
      docker compose logs -f
    else
      docker compose logs -f "$SERVICE"
    fi
    ;;

  clean)
    echo "Removing all data and containers..."
    read -p "Are you sure? This will delete all metrics and logs. (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      docker compose down -v
      echo "✓ All data removed"
    else
      echo "Cancelled"
    fi
    ;;

  health|check)
    echo "Checking health of all services..."
    echo ""

    echo -n "OTel Collector: "
    if curl -sf http://localhost:8888/metrics > /dev/null; then
      echo "✓ Healthy"
    else
      echo "✗ Unhealthy"
    fi

    echo -n "Prometheus:     "
    if curl -sf http://localhost:9090/-/healthy > /dev/null; then
      echo "✓ Healthy"
    else
      echo "✗ Unhealthy"
    fi

    echo -n "Loki:           "
    LOKI_STATUS=$(curl -s http://localhost:3100/ready)
    if echo "$LOKI_STATUS" | grep -q "ready"; then
      echo "✓ Healthy"
    else
      echo "⚠ $LOKI_STATUS"
    fi

    echo -n "Grafana:        "
    if curl -sf http://localhost:3030/api/health > /dev/null; then
      echo "✓ Healthy"
    else
      echo "✗ Unhealthy"
    fi
    ;;

  open)
    case "${2:-grafana}" in
      grafana)
        open http://localhost:3030
        ;;
      prometheus)
        open http://localhost:9090
        ;;
      loki)
        open http://localhost:3100
        ;;
      *)
        echo "Unknown service: ${2}"
        echo "Available: grafana, prometheus, loki"
        exit 1
        ;;
    esac
    ;;

  *)
    cat << 'EOF'
Claude Code OpenTelemetry Monitoring Stack Manager

Usage: ./manage.sh <command> [options]

Commands:
  start, up           Start all services
  stop, down          Stop all services
  restart             Restart all services
  status, ps          Show status of all services
  logs [service]      Show logs (optionally for specific service)
  clean               Remove all data and containers
  health, check       Check health of all services
  open [service]      Open service in browser (default: grafana)

Examples:
  ./manage.sh start
  ./manage.sh logs otel-collector
  ./manage.sh health
  ./manage.sh open prometheus
  ./manage.sh clean
EOF
    ;;
esac
