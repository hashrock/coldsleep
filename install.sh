#!/bin/bash
set -e

APP_NAME="Coldsleep"

# ビルド
./build.sh

# 既存のアプリを停止
pkill -x "$APP_NAME" 2>/dev/null && echo "既存の $APP_NAME を停止しました" || true

# インストール
echo "インストール中..."
rm -rf "/Applications/$APP_NAME.app"
cp -r "$APP_NAME.app" /Applications/

echo "完了: /Applications/$APP_NAME.app"
echo ""
echo "起動:"
echo "  open /Applications/$APP_NAME.app"
