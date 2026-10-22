#!/bin/bash
# 本地编译并安装 Topit（无开发者证书，ad-hoc 签名）。用法：scripts/build-local.sh
set -euo pipefail

cd "$(dirname "$0")/.."
APP=build/Build/Products/Release/Topit.app
DEST=/Applications/Topit.app
BUNDLE_ID=com.lihaoyun6.Topit

xcodebuild -project Topit.xcodeproj -scheme Topit -configuration Release \
    -derivedDataPath build CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
    build | grep -E "error:|BUILD"

# Sparkle 自带原作者的 Team ID 签名，需由内向外统一改为 ad-hoc
F="$APP/Contents/Frameworks/Sparkle.framework"
for x in "$F"/Versions/B/XPCServices/*.xpc "$F/Versions/B/Updater.app" "$F/Versions/B/Autoupdate" "$F"; do
    codesign --force --preserve-metadata=entitlements,flags --sign - "$x"
done
# ad-hoc 签名下 hardened runtime 的库校验无法通过，主程序不带 runtime 重签
codesign --force --entitlements Topit/Topit.entitlements --sign - "$APP"
codesign --verify --deep --strict "$APP"

osascript -e "quit app id \"$BUNDLE_ID\"" 2>/dev/null || true
sleep 1
pkill -x Topit 2>/dev/null || true

# 必须整体拷贝新文件：原地重签会被内核按 inode 缓存旧签名
rm -rf "$DEST"
ditto "$APP" "$DEST"

# 防止上游版本通过 Sparkle 覆盖本地修改
defaults write "$BUNDLE_ID" SUAutomaticallyUpdate -bool false
defaults write "$BUNDLE_ID" SUEnableAutomaticChecks -bool false

# 每次 ad-hoc 签名都会变，旧授权失效，重置后重新授权
tccutil reset ScreenCapture "$BUNDLE_ID"
tccutil reset Accessibility "$BUNDLE_ID"

open "$DEST"
echo "已安装。请在 系统设置 → 隐私与安全性 中重新开启「录屏与系统录音」和「辅助功能」，然后重启 Topit。"
