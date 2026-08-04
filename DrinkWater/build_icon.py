#!/usr/bin/env python3
"""为 macOS App 生成水滴图标 AppIcon.icns"""

import subprocess
import os
import shutil
from pathlib import Path

OUT_DIR = Path(__file__).parent / "build" / "饮水提醒.app" / "Contents" / "Resources"
ICNS_PATH = OUT_DIR / "AppIcon.icns"
TMP_DIR = Path("/tmp/drinkwater_iconset")
ICONSET_DIR = Path("/tmp/DrinkWater.iconset")

for d in [TMP_DIR, ICONSET_DIR]:
    if d.exists():
        shutil.rmtree(d)
TMP_DIR.mkdir()
ICONSET_DIR.mkdir()

swift_code = r"""
import Foundation
import AppKit

let sizes: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

let outDir = CommandLine.arguments[1]

for (size, name) in sizes {
    let s = CGFloat(size)

    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 32
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // ===== 背景：圆角方形 + 蓝紫渐变 =====
    let bgPath = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: s, height: s),
                              xRadius: s * 0.225, yRadius: s * 0.225)
    bgPath.addClip()

    let gradient = NSGradient(colors: [
        NSColor(red: 0.36, green: 0.82, blue: 1.00, alpha: 1.0),
        NSColor(red: 0.20, green: 0.55, blue: 1.00, alpha: 1.0),
        NSColor(red: 0.42, green: 0.36, blue: 0.95, alpha: 1.0)
    ])!
    gradient.draw(in: NSRect(x: 0, y: 0, width: s, height: s), angle: -90)

    // ===== 顶部高光 =====
    let highlight = NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.35),
        NSColor.white.withAlphaComponent(0.0)
    ])!
    highlight.draw(in: NSRect(x: 0, y: s * 0.55, width: s, height: s * 0.45), angle: -90)

    // ===== 白色水滴（居中偏上） =====
    let dropConfig = NSImage.SymbolConfiguration(pointSize: s * 0.56, weight: .bold)
        .applying(NSImage.SymbolConfiguration(paletteColors: [NSColor.white]))
    if let dropImage = NSImage(systemSymbolName: "drop.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(dropConfig) {
        let dropSize = s * 0.56
        let dropRect = NSRect(x: (s - dropSize) / 2,
                              y: s * 0.25,
                              width: dropSize, height: dropSize)
        dropImage.draw(in: dropRect)
    }

    // ===== 底部 "喝" 字胶囊标签 =====
    let pillH = s * 0.18
    let pillW = s * 0.38
    let pillX = (s - pillW) / 2
    let pillY = s * 0.06
    let pillRect = NSRect(x: pillX, y: pillY, width: pillW, height: pillH)

    let pillPath = NSBezierPath(roundedRect: pillRect,
                                xRadius: pillH / 2, yRadius: pillH / 2)
    NSColor.white.withAlphaComponent(0.88).setFill()
    pillPath.fill()

    // 标签内文字 "喝"
    let fontSize = s * 0.125
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center

    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont(name: "PingFangSC-Semibold", size: fontSize) ??
               NSFont.systemFont(ofSize: fontSize, weight: .semibold),
        .foregroundColor: NSColor(red: 0.20, green: 0.42, blue: 0.95, alpha: 1.0),
        .paragraphStyle: paragraphStyle
    ]

    let text = "喝" as NSString
    let textRect = NSRect(x: pillX, y: pillY, width: pillW, height: pillH + s * 0.01)
    text.draw(in: textRect, withAttributes: attrs)

    NSGraphicsContext.restoreGraphicsState()

    if let data = rep.representation(using: .png, properties: [:]) {
        let url = URL(fileURLWithPath: outDir + "/" + name)
        try? data.write(to: url)
    }
    print("生成: \(name)")
}
"""

swift_file = TMP_DIR / "gen_icons.swift"
swift_file.write_text(swift_code)

print("正在生成图标 PNG...")
subprocess.run(["swift", str(swift_file), str(ICONSET_DIR)], check=True)

print("\n正在合成 icns...")
subprocess.run(["iconutil", "-c", "icns", str(ICONSET_DIR), "-o", str(ICNS_PATH)], check=True)

print(f"✅ 图标已生成: {ICNS_PATH}")
print(f"   文件大小: {os.path.getsize(ICNS_PATH)} bytes")
