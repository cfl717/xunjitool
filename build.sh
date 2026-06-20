#!/bin/bash
# ============================================================
# 训记助手 — 鸿蒙安装包一键构建脚本
# 使用方式: bash build.sh
# 前置条件: DevEco Studio + HarmonyOS SDK 已安装
# 输出: ./build/outputs/default/
# ============================================================

set -e

echo "🏗️  训记助手 — 构建开始"
echo "========================"

# 1. 检查 Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装，请先安装 Node.js (v18+)"
    exit 1
fi
echo "✅ Node.js $(node --version)"

# 2. 检查 hvigor 是否可用
HVIGOR_CMD=""
if command -v hvigorw &> /dev/null; then
    HVIGOR_CMD="hvigorw"
elif [ -f "./node_modules/.bin/hvigorw" ]; then
    HVIGOR_CMD="./node_modules/.bin/hvigorw"
elif [ -f "./node_modules/.bin/hvigor" ]; then
    HVIGOR_CMD="./node_modules/.bin/hvigor"
fi

if [ -z "$HVIGOR_CMD" ]; then
    echo "⚠️  未找到 hvigor，尝试安装依赖..."
    npm install
    if [ -f "./node_modules/.bin/hvigorw" ]; then
        HVIGOR_CMD="./node_modules/.bin/hvigorw"
    else
        echo "❌ 安装后仍未找到 hvigor"
        echo ""
        echo "💡 解决方法：用 DevEco Studio 打开项目"
        echo "   它会自动下载 oh_modules + hvigor"
        echo "   然后: Build → Build HAP(s) / APP"
        exit 1
    fi
fi
echo "✅ 构建工具: $HVIGOR_CMD"

# 3. 检查训练数据
if [ ! -f "entry/src/main/resources/rawfile/training_data.json" ]; then
    echo "⚠️  training_data.json 不存在，创建空占位..."
    mkdir -p entry/src/main/resources/rawfile
    echo '{"data_by_date":{},"summary":{"days_with_data":0,"total_records":0}}' \
        > entry/src/main/resources/rawfile/training_data.json
fi
echo "✅ 训练数据就位"

# 4. 选择构建目标
echo ""
echo "📦 构建选项："
echo "  1) HAP (模块包) — 用于调试/快速测试"
echo "  2) APP (完整应用安装包) — 正式发布"
echo "  3) Debug HAP — 带调试信息的包"
read -p "请选择 [1-3] (默认 1): " build_target
build_target=${build_target:-1}

build_mode="release"
build_task="assembleHap"
output_name="HAP(Release)"

case $build_target in
    2)
        build_task="assembleApp"
        output_name="APP(Release)"
        ;;
    3)
        build_mode="debug"
        build_task="assembleHap"
        output_name="HAP(Debug)"
        ;;
esac

# 5. 执行构建
echo ""
echo "🔨 正在构建 $output_name ..."
echo "   命令: $HVIGOR_CMD --mode $build_mode $build_task"
echo ""

if $HVIGOR_CMD --mode $build_mode $build_task; then
    echo ""
    echo "✅ ===== 构建成功! ====="
    echo "输出目录: build/outputs/default/"
    echo ""

    find build/outputs -name "*.hap" -o -name "*.app" 2>/dev/null | while read f; do
        size=$(du -h "$f" | cut -f1)
        echo "   📄 $f ($size)"
    done
    echo ""
    echo "将 .hap 或 .app 通过 DevEco Studio 或 hdc 安装到设备即可"
else
    echo ""
    echo "❌ 构建失败"
    echo "   请用 DevEco Studio 打开项目查看详细错误"
    exit 1
fi
