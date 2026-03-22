#!/bin/bash
set -e

APP_NAME="Coldsleep"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "ビルド中..."
swift build -c release

echo "アプリバンドル作成中..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources/MenuBarIcon"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"
cp "$SCRIPT_DIR/Info.plist" "$APP_BUNDLE/Contents/"
cp "$SCRIPT_DIR/icons/Coldsleep.icns" "$APP_BUNDLE/Contents/Resources/"
cp "$SCRIPT_DIR/icons/menubar/icon.png" "$APP_BUNDLE/Contents/Resources/MenuBarIcon/"
cp "$SCRIPT_DIR/icons/menubar/icon@2x.png" "$APP_BUNDLE/Contents/Resources/MenuBarIcon/"

echo "完了: $APP_BUNDLE"
echo ""
echo "使い方:"
echo "  open $APP_BUNDLE"
echo ""
echo "注意: 初回起動時に以下の許可が必要です:"
echo "  1. マイクアクセス（自動で許可ダイアログが出ます）"
echo "  2. アクセシビリティ（システム設定 > プライバシーとセキュリティ > アクセシビリティ）"
