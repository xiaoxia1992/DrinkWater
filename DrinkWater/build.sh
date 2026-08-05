#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="饮水提醒.app"
APP_DIR="$BUILD_DIR/$APP_NAME"
SOURCES_DIR="$PROJECT_DIR/Sources"
RESOURCES_DIR="$PROJECT_DIR/Resources"
BINARY_PATH="$APP_DIR/Contents/MacOS/DrinkWater"

echo "🔨 正在编译饮水提醒应用..."

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
echo "📦 应用位置: $APP_DIR"
echo ""
echo "你可以双击打开应用，或运行:"
echo "  open \"$APP_DIR\""
echo ""
read -p "是否立即启动应用？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "$APP_DIR"
    echo "应用已启动"
fi
