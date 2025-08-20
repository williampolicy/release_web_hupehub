#!/bin/bash
# 生产环境监控

echo "🔍 生产环境监控"
echo "=================="

# 检查主域名
echo -n "主域名 (hopehub.x1000.ai): "
curl -s -o /dev/null -w "%{http_code}" https://hopehub.x1000.ai && echo " ✅" || echo " ❌"

# 检查短域名
echo -n "短域名 (hh.x1000.ai): "
curl -s -o /dev/null -w "%{http_code}" https://hh.x1000.ai && echo " ✅" || echo " ❌"

# 检查API健康
echo -n "API健康检查: "
curl -s https://hopehub.x1000.ai/api/health | grep -q "healthy" && echo "✅" || echo "❌"

# 检查支付配置
echo -n "Stripe配置: "
curl -s https://hopehub.x1000.ai/api/stripe_config | grep -q "publishable_key" && echo "✅" || echo "❌"
