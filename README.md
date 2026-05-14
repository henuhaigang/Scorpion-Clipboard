# ScorpionClipboard

macOS 原生剪贴板管理器，支持历史记录、快速粘贴、忽略应用等功能。

## 功能特性

- 剪贴板历史记录（文本/RTF/图片/文件）
- 全局快捷键呼出面板
- 数字键快速选择粘贴
- 搜索过滤历史记录
- 忽略指定应用
- 菜单栏常驻
- 支持明暗模式

## 技术栈

- Swift 5.9+
- SwiftUI + AppKit
- macOS 14 (Sonoma)
- KeyboardShortcuts

## 安装

```bash
swift build
swift run ScorpionClipboard
```

## 使用

1. 启动后菜单栏出现剪贴板图标
2. 点击图标 → "显示面板" 查看历史
3. 按 `⌃ + 数字键` 快速粘贴
4. 点击条目也可粘贴
5. 偏好设置中可配置快捷键、历史上限等

## 打包分发

```bash
# 1. 编译 Release 版本
swift build -c release --arch arm64

# 2. 创建 .app 目录结构
rm -rf /tmp/ScorpionClipboard.app
mkdir -p /tmp/ScorpionClipboard.app/Contents/MacOS
mkdir -p /tmp/ScorpionClipboard.app/Contents/Resources
cp .build/arm64-apple-macosx/release/ScorpionClipboard /tmp/ScorpionClipboard.app/Contents/MacOS/
cp Resources/AppIcon.icns /tmp/ScorpionClipboard.app/Contents/Resources/

# 3. 创建 Info.plist
cat > /tmp/ScorpionClipboard.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ScorpionClipboard</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>CFBundleIdentifier</key>
    <string>com.scorpion.ScorpionClipboard</string>
    <key>CFBundleName</key>
    <string>ScorpionClipboard</string>
    <key>CFBundleDisplayName</key>
    <string>ScorpionClipboard</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# 4. 创建 Entitlements
cat > /tmp/scorpion-entitlements.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
</dict>
</plist>
EOF

# 5. Ad-hoc 签名
codesign --force --sign - --entitlements /tmp/scorpion-entitlements.plist /tmp/ScorpionClipboard.app

# 6. 打包 DMG
rm -rf /tmp/dmg-content
mkdir -p /tmp/dmg-content
cp -R /tmp/ScorpionClipboard.app /tmp/dmg-content/
ln -sf /Applications /tmp/dmg-content/Applications
hdiutil create -volname "ScorpionClipboard" -srcfolder /tmp/dmg-content -ov -format UDZO /tmp/ScorpionClipboard-1.0.dmg

# 输出文件：/tmp/ScorpionClipboard-1.0.dmg
```

> **注意**：Ad-hoc 签名（`--sign -`）的 app 无法通过 Gatekeeper，首次打开需右键 → "打开"。
> 自动粘贴需要前往 **系统设置 → 隐私与安全性 → 辅助功能** 中授权。

## 已知问题

- 自动粘贴（模拟 Cmd+V）在部分应用中不生效，需手动按 Cmd+V
- 需要辅助功能权限才能使用自动粘贴

## 许可证

MIT
