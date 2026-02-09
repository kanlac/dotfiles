#!/bin/bash

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查必要工具
if ! command -v jq &> /dev/null; then
    echo_error "jq 未安装，请先运行: brew install jq"
    exit 1
fi

# 配置
REPO="lbjlaq/Antigravity-Manager"
APP_NAME="Antigravity Tools"
APP_PATH="/Applications/${APP_NAME}.app"
TMP_DIR="/tmp/antigravity-update"

# 清理临时目录
cleanup() {
    if [ -d "$TMP_DIR" ]; then
        echo_info "清理临时文件..."
        rm -rf "$TMP_DIR"
    fi
    # 确保卸载 dmg
    if mount | grep -q "Antigravity"; then
        hdiutil detach "/Volumes/Antigravity Tools" -quiet 2>/dev/null || true
    fi
}

trap cleanup EXIT

# 获取最新版本信息
echo_info "正在获取最新版本信息..."
RELEASE_JSON=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest")

if [ -z "$RELEASE_JSON" ]; then
    echo_error "无法获取 release 信息"
    exit 1
fi

LATEST_VERSION=$(echo "$RELEASE_JSON" | jq -r '.tag_name')
echo_info "最新版本: ${LATEST_VERSION}"

# 检查当前版本
if [ -d "$APP_PATH" ]; then
    CURRENT_VERSION=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "未知")
    echo_info "当前版本: ${CURRENT_VERSION}"

    if [ "$CURRENT_VERSION" = "${LATEST_VERSION#v}" ]; then
        echo_info "已经是最新版本"
        read -p "是否继续重新安装？(y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
fi

# 查找 aarch64 dmg 下载链接
DOWNLOAD_URL=$(echo "$RELEASE_JSON" | jq -r '.assets[] | select(.name | contains("aarch64.dmg")) | .browser_download_url')

if [ -z "$DOWNLOAD_URL" ]; then
    echo_error "未找到 aarch64.dmg 文件"
    exit 1
fi

DMG_NAME=$(basename "$DOWNLOAD_URL")
echo_info "下载链接: ${DOWNLOAD_URL}"

# 创建临时目录
mkdir -p "$TMP_DIR"
DMG_PATH="${TMP_DIR}/${DMG_NAME}"

# 下载 dmg
echo_info "正在下载 ${DMG_NAME}..."
if ! curl -L -o "$DMG_PATH" "$DOWNLOAD_URL" --progress-bar; then
    echo_error "下载失败"
    exit 1
fi

# 检查并退出应用
if pgrep -x "Antigravity Tools" > /dev/null; then
    echo_info "正在退出 Antigravity Tools..."
    osascript -e "quit app \"${APP_NAME}\"" 2>/dev/null || true
    sleep 2
fi

# 如果应用还在运行，强制退出
if pgrep -x "Antigravity Tools" > /dev/null; then
    echo_warn "强制退出应用..."
    pkill -9 "Antigravity Tools" || true
    sleep 1
fi

# 挂载 dmg
echo_info "正在挂载 dmg..."
MOUNT_POINT=$(hdiutil attach "$DMG_PATH" -nobrowse | grep "/Volumes" | sed 's/.*\/Volumes/\/Volumes/')

if [ -z "$MOUNT_POINT" ]; then
    echo_error "挂载失败"
    exit 1
fi

echo_info "挂载点: ${MOUNT_POINT}"

# 删除旧版本
if [ -d "$APP_PATH" ]; then
    echo_info "删除旧版本..."
    sudo rm -rf "$APP_PATH"
fi

# 复制新版本
echo_info "正在安装..."
sudo cp -R "${MOUNT_POINT}/${APP_NAME}.app" "/Applications/"

# 卸载 dmg
echo_info "正在卸载 dmg..."
hdiutil detach "$MOUNT_POINT" -quiet

# 解除 quarantine
echo_info "正在解除 quarantine 属性..."
if sudo xattr -rd com.apple.quarantine "$APP_PATH"; then
    echo_info "✓ 成功解除 quarantine"
else
    echo_warn "解除 quarantine 失败，可能需要手动执行: sudo xattr -rd com.apple.quarantine \"$APP_PATH\""
fi

echo_info "✓ 更新完成！版本: ${LATEST_VERSION}"

# 询问是否打开应用
read -p "是否现在打开应用？(Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo_info "正在打开 ${APP_NAME}..."
    open "$APP_PATH"
fi
