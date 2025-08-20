#!/bin/bash
# 生产环境启动脚本

# 加载环境变量
source configs/production.env

# 启动后端
cd production
pkill -f stripe_server.py
nohup python3 stripe_server.py > production.log 2>&1 &
echo "✅ 后端服务已启动 (PID: $!)"

# 启动前端
cd ../website
pkill -f "http.server 8000"
nohup python3 -m http.server 8000 > web.log 2>&1 &
echo "✅ 前端服务已启动 (PID: $!)"

cd ..
echo ""
echo "生产环境已启动:"
echo "  主域名: https://hopehub.x1000.ai"
echo "  短域名: https://hh.x1000.ai"
echo "  监控: https://hopehub.x1000.ai/monitor.html"
