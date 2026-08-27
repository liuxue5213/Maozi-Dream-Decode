#!/bin/bash
# 帽子解梦后端服务管理脚本
cd "$(dirname "$0")/../backend"

case "$1" in
  start)
    source .venv/bin/activate
    nohup uvicorn app.main:app --host 0.0.0.0 --port 60185 > /tmp/dream-api.log 2>&1 &
    sleep 3
    curl -s -o /dev/null -w "服务状态: %{http_code}\n" http://localhost:60185/docs && echo "✅ 已启动 http://$(ipconfig getifaddr en0):60185"
    ;;
  stop)
    pkill -f "uvicorn app.main" && echo "🛑 已停止"
    ;;
  status)
    curl -s -o /dev/null -w "服务状态: %{http_code}\n" --max-time 3 http://localhost:60185/docs
    ;;
  logs)
    tail -f /tmp/dream-api.log
    ;;
  *)
    echo "用法: ./scripts/server.sh {start|stop|status|logs}"
    ;;
esac
