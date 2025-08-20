#!/bin/bash
# render_deploy.sh
# ========================================
# 一键部署到Render
# ========================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

RELEASE_DIR="/home/kangxiaowen/code_lh_server/code_lh_pj_ai/pj_801_tools_m025_lh_pj_prj_knowledge_v3/_release_wb_hopehub"

echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  🚀 一键部署到Render                                     ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"

cd $RELEASE_DIR

# 初始化Git
if [ ! -d ".git" ]; then
    echo "初始化Git仓库..."
    git init
    git add .
    git commit -m "Initial commit: HopeHub MVP v1.0"
fi
# https://github.com/williampolicy/hopehub-production.git

# 创建GitHub仓库（需要GitHub CLI）
echo ""
echo -e "${YELLOW}请在GitHub创建新仓库: hopehub-production${NC}"
echo "然后运行以下命令:"
echo ""
echo "git remote add origin https://github.com/williampolicy/hopehub-production.git"
echo "git branch -M main"
echo "git push -u origin main"
echo ""
echo "在Render.com:"
echo "1. 连接GitHub仓库"
echo "2. 选择render.yaml自动配置"
echo "3. 配置自定义域名"
echo ""
echo -e "${GREEN}部署后访问: https://hopehub.x1000.ai${NC}"
