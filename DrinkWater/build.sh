#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="饮水提醒.app"
APP_DIR="$BUILD_DIR/$APP_NAME"
SOURCES_DIR="$PROJECT_DIR/Sources"
RESOURCES_DIR="$PROJECT_DIR/Resources"
BINARY_PATH="$APP_DIR/Contents/MacOS/DrinkWater"
INSTALL_DIR="/Applications/$APP_NAME"

echo "🔨 正在编译饮水提醒应用..."

# 杀掉旧进程
pkill -f "饮水提醒" 2>/dev/null || true
pkill -f "DrinkWater" 2>/dev/null || true
sleep 1

rm -rf "$BUILD_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

echo "  编译 Swift 源文件..."
swiftc \
    -o "$BINARY_PATH" \
    -framework Cocoa \
    -framework SwiftUI \
    -framework Combine \
    -framework UserNotifications \
    -O \
    "$SOURCES_DIR/WaterData.swift" \
    "$SOURCES_DIR/AppLog.swift" \
    "$SOURCES_DIR/ContentView.swift" \
    "$SOURCES_DIR/SettingsView.swift" \
    "$SOURCES_DIR/UnifiedPanelView.swift" \
    "$SOURCES_DIR/ReminderView.swift" \
    "$SOURCES_DIR/AppDelegate.swift" \
    "$SOURCES_DIR/DrinkWaterApp.swift"

cp "$RESOURCES_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
chmod +x "$BINARY_PATH"

echo "  生成 App 图标..."
python3 "$PROJECT_DIR/build_icon.py" 2>&1 | grep -E "✅|错误" || true

echo ""
echo "✅ 构建完成！"

# 安装到 /Applications
echo "📦 正在安装到 /Applications..."
rm -rf "$INSTALL_DIR"
cp -R "$APP_DIR" "$INSTALL_DIR"
echo "✅ 已安装到 $INSTALL_DIR"

# 启动
open "$INSTALL_DIR"
echo "🚀 应用已启动"
