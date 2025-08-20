#!/bin/bash
# real_world_test_console.sh
# ========================================
# 真实世界完整测试控制台 - 121控制台大法
# 可重复使用的里程碑测试基准
# ========================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GOLD='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 版本信息
VERSION="1.0.0"
TEST_DATE=$(date +"%Y-%m-%d %H:%M:%S")
BASELINE_FILE=".test_baseline"
RESULTS_DIR="test_results"
CURRENT_RESULT="$RESULTS_DIR/test_$(date +%Y%m%d_%H%M%S).json"

# 创建结果目录
mkdir -p $RESULTS_DIR

# 测试统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNINGS=0

# 测试类别统计
declare -A CATEGORY_STATS

echo -e "${GOLD}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GOLD}║  🎯 真实世界完整测试控制台 v${VERSION}                    ║${NC}"
echo -e "${GOLD}║     基于121控制台大法 - 里程碑固化版                    ║${NC}"
echo -e "${GOLD}╚══════════════════════════════════════════════════════════╝${NC}"

# ========================================
# 测试函数（增强版）
# ========================================
run_test() {
    local category="$1"
    local test_name="$2"
    local test_cmd="$3"
    local expected="$4"
    local test_type="${5:-exact}"  # exact, contains, regex, numeric
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    CATEGORY_STATS["$category"]=$((${CATEGORY_STATS["$category"]:-0} + 1))
    
    echo -n "  [$TOTAL_TESTS] $test_name: "
    
    # 执行测试（带超时）
    result=$(timeout 5 bash -c "$test_cmd" 2>/dev/null)
    exit_code=$?
    
    # 根据测试类型判断
    local test_passed=false
    case "$test_type" in
        "exact")
            [[ "$result" == "$expected" ]] && test_passed=true
            ;;
        "contains")
            [[ "$result" == *"$expected"* ]] && test_passed=true
            ;;
        "regex")
            [[ "$result" =~ $expected ]] && test_passed=true
            ;;
        "numeric")
            if [[ "$result" =~ ^[0-9]+$ ]] && [[ "$expected" =~ ^[0-9]+$ ]]; then
                [[ "$result" -eq "$expected" ]] && test_passed=true
            elif [[ "$result" =~ ^[0-9]+$ ]]; then
                # 只要是数字就通过
                test_passed=true
            fi
            ;;
    esac
    
    if [ "$test_passed" = true ]; then
        echo -e "${GREEN}✅ PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo "{\"test\":\"$test_name\",\"category\":\"$category\",\"status\":\"PASS\",\"result\":\"$result\"}" >> $CURRENT_RESULT
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        echo "     期望: $expected ($test_type)"
        echo "     实际: ${result:0:60}..."
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo "{\"test\":\"$test_name\",\"category\":\"$category\",\"status\":\"FAIL\",\"expected\":\"$expected\",\"actual\":\"$result\"}" >> $CURRENT_RESULT
        return 1
    fi
}

# ========================================
# 第1层：完整测试（Test Layer）
# ========================================
echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${CYAN}  第1层：完整真实测试 (Test Layer)     ${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# 1. 环境测试
echo -e "\n${YELLOW}[1] 环境与依赖测试${NC}"
run_test "环境" "Python版本" "python3 --version | grep -o 'Python 3\.[0-9]\+'" "Python 3\.[0-9]+" "regex"
run_test "环境" "Flask安装" "python3 -c 'import flask; print(\"OK\")' 2>/dev/null" "OK" "exact"
run_test "环境" "SQLite版本" "sqlite3 --version | grep -o '^3\.[0-9]\+'" "3\.[0-9]+" "regex"
run_test "环境" "项目结构" "[ -d HOPEHUB_FINAL ] && echo 'OK'" "OK" "exact"
run_test "环境" "生产目录" "[ -d HOPEHUB_FINAL/production ] && echo 'OK'" "OK" "exact"
run_test "环境" "网站目录" "[ -d HOPEHUB_FINAL/website ] && echo 'OK'" "OK" "exact"

# 2. 服务状态测试
echo -e "\n${YELLOW}[2] 服务运行状态测试${NC}"
run_test "服务" "后端进程" "pgrep -f 'zipcode_server' > /dev/null && echo 'RUNNING'" "RUNNING" "exact"
run_test "服务" "前端进程" "pgrep -f 'http.server.*8000' > /dev/null && echo 'RUNNING'" "RUNNING" "exact"
run_test "服务" "5000端口" "netstat -tln 2>/dev/null | grep -q ':5000 ' && echo 'LISTENING'" "LISTENING" "exact"
run_test "服务" "8000端口" "netstat -tln 2>/dev/null | grep -q ':8000 ' && echo 'LISTENING'" "LISTENING" "exact"

# 3. API端点测试
echo -e "\n${YELLOW}[3] API端点功能测试${NC}"
run_test "API" "Health端点" "curl -s http://localhost:5000/api/health | jq -r .status 2>/dev/null" "healthy" "exact"
run_test "API" "Health时间戳" "curl -s http://localhost:5000/api/health | grep -o 'timestamp'" "timestamp" "contains"
run_test "API" "Positions端点" "curl -s http://localhost:5000/api/positions | jq '. | length' 2>/dev/null" "[0-9]+" "regex"
run_test "API" "Login端点" "curl -s -X POST http://localhost:5000/api/login -H 'Content-Type: application/json' -d '{\"email\":\"test@demo.com\",\"password\":\"123456\"}' | jq -r .success 2>/dev/null" "true" "exact"
run_test "API" "Register端点" "curl -s -X POST http://localhost:5000/api/register -H 'Content-Type: application/json' -d '{\"email\":\"test$(date +%s)@test.com\",\"password\":\"123456\"}' | grep -o 'success'" "success" "contains"
run_test "API" "Recharge端点" "curl -s -X POST http://localhost:5000/api/recharge -H 'Content-Type: application/json' -d '{\"amount\":100}' | grep -o 'success'" "success" "contains"
run_test "API" "Buy端点" "curl -s -X POST http://localhost:5000/api/buy_position -H 'Content-Type: application/json' -d '{\"position_id\":1}' | grep -o 'success'" "success" "contains"

# 4. 前端页面测试
echo -e "\n${YELLOW}[4] 前端页面可访问性测试${NC}"
run_test "前端" "主页HTTP状态" "curl -s -o /dev/null -w '%{http_code}' http://localhost:8000/" "200" "exact"
run_test "前端" "用户指南页面" "curl -s http://localhost:8000/user_guide.html | grep -o '<title>.*</title>' | head -1" "HopeHub" "contains"
run_test "前端" "购买流程页面" "curl -s http://localhost:8000/purchase_flow.html | grep -o 'HopeHub' | head -1" "HopeHub" "exact"
run_test "前端" "仪表板页面" "curl -s http://localhost:8000/dashboard.html | grep -o 'dashboard' | head -1" "dashboard" "contains"
run_test "前端" "管理后台页面" "curl -s http://localhost:8000/admin_dashboard.html | grep -o '管理' | head -1" "管理" "exact"
run_test "前端" "用户流程页面" "curl -s http://localhost:8000/user_flow.html | grep -o 'DOCTYPE' | head -1" "DOCTYPE" "exact"
run_test "前端" "监控页面" "curl -s http://localhost:8000/monitor.html | grep -o 'monitor' | head -1" "monitor" "contains"

# 5. 数据库测试
echo -e "\n${YELLOW}[5] 数据库完整性测试${NC}"
DB_PATH="HOPEHUB_FINAL/production/production.db"
run_test "数据库" "数据库文件" "[ -f $DB_PATH ] && echo 'EXISTS'" "EXISTS" "exact"
run_test "数据库" "数据库大小" "[ -f $DB_PATH ] && [ -s $DB_PATH ] && echo 'NOT_EMPTY'" "NOT_EMPTY" "exact"
run_test "数据库" "用户表存在" "sqlite3 $DB_PATH '.tables' 2>/dev/null | grep -o 'users'" "users" "exact"
run_test "数据库" "位置表存在" "sqlite3 $DB_PATH '.tables' 2>/dev/null | grep -o 'positions_v2'" "positions_v2" "exact"
run_test "数据库" "用户数量" "sqlite3 $DB_PATH 'SELECT COUNT(*) FROM users;' 2>/dev/null" "[0-9]+" "regex"
run_test "数据库" "位置数量" "sqlite3 $DB_PATH 'SELECT COUNT(*) FROM positions_v2;' 2>/dev/null" "[0-9]+" "regex"
run_test "数据库" "测试账号" "sqlite3 $DB_PATH \"SELECT email FROM users WHERE email='test@demo.com';\" 2>/dev/null" "test@demo.com" "exact"
run_test "数据库" "VIP账号" "sqlite3 $DB_PATH \"SELECT email FROM users WHERE email='vip@demo.com';\" 2>/dev/null" "vip@demo.com" "exact"

# 6. 用户流程测试
echo -e "\n${YELLOW}[6] 端到端用户流程测试${NC}"
# 生成唯一测试邮箱
TEST_EMAIL="test_$(date +%s)@test.com"
run_test "流程" "新用户注册" "curl -s -X POST http://localhost:5000/api/register -H 'Content-Type: application/json' -d '{\"email\":\"$TEST_EMAIL\",\"password\":\"123456\"}' | jq -r .success 2>/dev/null" "true" "exact"
run_test "流程" "用户登录" "curl -s -X POST http://localhost:5000/api/login -H 'Content-Type: application/json' -d '{\"email\":\"test@demo.com\",\"password\":\"123456\"}' | jq -r .success 2>/dev/null" "true" "exact"
run_test "流程" "查询位置" "curl -s http://localhost:5000/api/positions | jq 'length > 0' 2>/dev/null" "true" "exact"
run_test "流程" "充值积分" "curl -s -X POST http://localhost:5000/api/recharge -H 'Content-Type: application/json' -d '{\"user_id\":1,\"amount\":1000}' | grep -o 'success'" "success" "contains"
run_test "流程" "购买位置" "curl -s -X POST http://localhost:5000/api/buy_position -H 'Content-Type: application/json' -d '{\"user_id\":1,\"position_id\":10}' | grep -o 'success'" "success" "contains"

# 7. 性能测试
echo -e "\n${YELLOW}[7] 性能基准测试${NC}"
run_test "性能" "Health响应时间" "curl -w '%{time_total}' -o /dev/null -s http://localhost:5000/api/health | awk '{if(\$1<0.1) print \"FAST\"; else print \"SLOW\"}'" "FAST" "exact"
run_test "性能" "Positions响应时间" "curl -w '%{time_total}' -o /dev/null -s http://localhost:5000/api/positions | awk '{if(\$1<0.5) print \"FAST\"; else print \"SLOW\"}'" "FAST" "exact"
run_test "性能" "静态页面响应" "curl -w '%{time_total}' -o /dev/null -s http://localhost:8000/index.html | awk '{if(\$1<0.05) print \"FAST\"; else print \"SLOW\"}'" "FAST" "exact"

# ========================================
# 第2层：智能诊断（Diagnose Layer）
# ========================================
echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${CYAN}  第2层：智能诊断 (Diagnose Layer)     ${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

echo -e "\n${BLUE}测试统计分析:${NC}"
echo "总测试数: $TOTAL_TESTS"
echo "通过数: ${GREEN}$PASSED_TESTS${NC}"
echo "失败数: ${RED}$FAILED_TESTS${NC}"
echo "通过率: $((PASSED_TESTS * 100 / TOTAL_TESTS))%"

echo -e "\n${BLUE}分类统计:${NC}"
for category in "${!CATEGORY_STATS[@]}"; do
    echo "  $category: ${CATEGORY_STATS[$category]} 个测试"
done

# 诊断问题
if [ $FAILED_TESTS -gt 0 ]; then
    echo -e "\n${YELLOW}问题诊断:${NC}"
    # 分析失败的测试类型
    if grep -q '"category":"环境".*"status":"FAIL"' $CURRENT_RESULT 2>/dev/null; then
        echo "  ⚠️ 环境配置问题"
    fi
    if grep -q '"category":"服务".*"status":"FAIL"' $CURRENT_RESULT 2>/dev/null; then
        echo "  ⚠️ 服务未正常运行"
    fi
    if grep -q '"category":"API".*"status":"FAIL"' $CURRENT_RESULT 2>/dev/null; then
        echo "  ⚠️ API接口异常"
    fi
    if grep -q '"category":"数据库".*"status":"FAIL"' $CURRENT_RESULT 2>/dev/null; then
        echo "  ⚠️ 数据库问题"
    fi
fi

# ========================================
# 第3层：基准对比（Baseline Compare）
# ========================================
echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${CYAN}  第3层：基准对比 (Baseline Layer)     ${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# 保存当前基准
save_baseline() {
    cat > $BASELINE_FILE << EOF
# HopeHub测试基准 - $(date)
BASELINE_VERSION=$VERSION
BASELINE_DATE=$TEST_DATE
BASELINE_TOTAL=$TOTAL_TESTS
BASELINE_PASSED=$PASSED_TESTS
BASELINE_FAILED=$FAILED_TESTS
BASELINE_PASS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
EOF
    echo -e "${GREEN}✅ 基准已保存${NC}"
}

# 比较基准
if [ -f "$BASELINE_FILE" ]; then
    source $BASELINE_FILE
    echo -e "\n${BLUE}与基准对比:${NC}"
    echo "基准日期: $BASELINE_DATE"
    echo "基准通过率: $BASELINE_PASS_RATE%"
    echo "当前通过率: $((PASSED_TESTS * 100 / TOTAL_TESTS))%"
    
    if [ $((PASSED_TESTS * 100 / TOTAL_TESTS)) -ge $BASELINE_PASS_RATE ]; then
        echo -e "${GREEN}✅ 达到或超过基准${NC}"
    else
        echo -e "${YELLOW}⚠️ 低于基准${NC}"
    fi
    
    echo ""
    read -p "是否更新基准? (y/n): " update_baseline
    if [ "$update_baseline" = "y" ]; then
        save_baseline
    fi
else
    echo "首次运行，保存为基准..."
    save_baseline
fi

# ========================================
# 生成测试报告
# ========================================
REPORT_FILE="$RESULTS_DIR/report_$(date +%Y%m%d_%H%M%S).md"
cat > $REPORT_FILE << EOF
# 真实世界测试报告

生成时间: $TEST_DATE
测试版本: $VERSION

## 测试结果

| 指标 | 数值 | 状态 |
|------|------|------|
| 总测试数 | $TOTAL_TESTS | - |
| 通过数 | $PASSED_TESTS | $([ $PASSED_TESTS -eq $TOTAL_TESTS ] && echo "✅" || echo "⚠️") |
| 失败数 | $FAILED_TESTS | $([ $FAILED_TESTS -eq 0 ] && echo "✅" || echo "❌") |
| 通过率 | $((PASSED_TESTS * 100 / TOTAL_TESTS))% | $([ $((PASSED_TESTS * 100 / TOTAL_TESTS)) -ge 90 ] && echo "✅" || echo "⚠️") |

## 分类统计

| 类别 | 测试数 |
|------|--------|
$(for cat in "${!CATEGORY_STATS[@]}"; do
    echo "| $cat | ${CATEGORY_STATS[$cat]} |"
done)

## 系统状态

- 环境配置: $(grep -q '"category":"环境".*"status":"FAIL"' $CURRENT_RESULT 2>/dev/null && echo "❌ 异常" || echo "✅ 正常")
- 服务运行: $(grep -q '"category":"服务".*"status":"FAIL"' $CURRENT_RESULT 2>/dev/null && echo "❌ 异常" || echo "✅ 正常")
- API接口: $(grep -q '"category":"API".*"status":"FAIL"' $CURRENT_RESULT 2>/dev/null && echo "❌ 异常" || echo "✅ 正常")
- 数据库: $(grep -q '"category":"数据库".*"status":"FAIL"' $CURRENT_RESULT 2>/dev/null && echo "❌ 异常" || echo "✅ 正常")
- 用户流程: $(grep -q '"category":"流程".*"status":"FAIL"' $CURRENT_RESULT 2>/dev/null && echo "❌ 异常" || echo "✅ 正常")
- 性能: $(grep -q '"category":"性能".*"status":"FAIL"' $CURRENT_RESULT 2>/dev/null && echo "❌ 异常" || echo "✅ 正常")

## 测试详情

详细结果见: $CURRENT_RESULT

---
*基于121控制台大法生成*
EOF

# ========================================
# 最终总结
# ========================================
echo -e "\n${GOLD}═══════════════════════════════════════${NC}"
echo -e "${GOLD}         测试完成总结                   ${NC}"
echo -e "${GOLD}═══════════════════════════════════════${NC}"

if [ $((PASSED_TESTS * 100 / TOTAL_TESTS)) -ge 95 ]; then
    echo -e "${GREEN}🏆 优秀！系统运行完美${NC}"
elif [ $((PASSED_TESTS * 100 / TOTAL_TESTS)) -ge 90 ]; then
    echo -e "${GREEN}✅ 良好！系统运行正常${NC}"
elif [ $((PASSED_TESTS * 100 / TOTAL_TESTS)) -ge 80 ]; then
    echo -e "${YELLOW}⚠️ 一般！需要关注失败项${NC}"
else
    echo -e "${RED}❌ 警告！系统存在问题${NC}"
fi

echo -e "\n📊 报告已生成: $REPORT_FILE"
echo "📁 测试数据: $CURRENT_RESULT"
echo "📈 基准文件: $BASELINE_FILE"

# 快速访问
echo -e "\n${CYAN}快速命令:${NC}"
echo "  查看报告: cat $REPORT_FILE"
echo "  查看基准: cat $BASELINE_FILE"
echo "  查看详情: jq . $CURRENT_RESULT"
