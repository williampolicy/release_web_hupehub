# 域名配置指南

## Namecheap DNS设置

### 主域名: hopehub.x1000.ai
```
Type: CNAME
Host: hopehub
Value: hopehub-frontend.onrender.com
TTL: Automatic
```

### 短域名: hh.x1000.ai
```
Type: CNAME
Host: hh
Value: hopehub-frontend.onrender.com
TTL: Automatic
```

### API域名: api.hopehub.x1000.ai
```
Type: CNAME
Host: api.hopehub
Value: hopehub-api.onrender.com
TTL: Automatic
```

## SSL证书
Render自动提供Let's Encrypt SSL证书

## 验证命令
```bash
# 验证DNS
dig hopehub.x1000.ai
dig hh.x1000.ai

# 验证HTTPS
curl https://hopehub.x1000.ai/api/health
```
