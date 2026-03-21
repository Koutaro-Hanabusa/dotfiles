#!/bin/bash

# Claude Code OTel Monitoring Stack Management Script
# Grafana Cloud edition: otel-collector + promtail only

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

case "${1:-}" in
  start|up)
    echo "Starting Claude Code monitoring stack..."
    docker compose up -d
    echo ""
    echo "✓ otel-collector + promtail are running"
    echo ""
    echo "Endpoints:"
    echo "  OTel gRPC:  localhost:4317"
    echo "  OTel HTTP:  localhost:4318"
    echo "  Dashboard:  https://grafana.com (Grafana Cloud)"
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
    echo "Removing all containers..."
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      docker compose down -v
      echo "✓ All containers removed"
    else
      echo "Cancelled"
    fi
    ;;

  health|check)
    echo "Checking health of services..."
    echo ""

    echo -n "OTel Collector: "
    if curl -sf http://localhost:8888/metrics > /dev/null; then
      echo "✓ Healthy"
    else
      echo "✗ Unhealthy"
    fi

    echo -n "Promtail:       "
    if docker compose ps promtail --format '{{.Status}}' 2>/dev/null | grep -q "Up"; then
      echo "✓ Running"
    else
      echo "✗ Not running"
    fi
    ;;

  *)
    cat << 'EOF'
Claude Code OTel Monitoring Stack Manager (Grafana Cloud)

Usage: ./manage.sh <command> [options]

Commands:
  start, up           Start all services
  stop, down          Stop all services
  restart             Restart all services
  status, ps          Show status of all services
  logs [service]      Show logs (optionally for specific service)
  clean               Remove all containers
  health, check       Check health of all services

Services: otel-collector, promtail

Examples:
  ./manage.sh start
  ./manage.sh logs otel-collector
  ./manage.sh health
  ./manage.sh clean
EOF
    ;;
esac
