#!/usr/bin/env swift
// 生成多环表盘应用图标（Apple Watch 活动环风格）：
// 深色底 + 三色同心环（品牌色：Codex 绿 / Claude 橙 / DeepSeek 蓝）。
// 输出 QuotaBar.iconset 各尺寸 PNG，再由 iconutil 打包为 icns。

import AppKit
import CoreGraphics
import Foundation

let size: CGFloat = 1024
let ringColors: [CGColor] = [
    CGColor(red: 0.373, green: 0.831, blue: 0.671, alpha: 1),  // #5FD4AB
    CGColor(red: 0.941, green: 0.612, blue: 0.388, alpha: 1),  // #F09C63
    CGColor(red: 0.349, green: 0.761, blue: 0.961, alpha: 1),  // #59C2F5
]
// 每环弧长（占整圆比例），模拟"进行中"的活动环。
let ringFractions: [CGFloat] = [0.86, 0.72, 0.58]

func drawIcon(pixelSize: CGFloat) -> Data? {
    let width = Int(pixelSize), height = Int(pixelSize)
    var data = Data(count: height * width * 4)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = data.withUnsafeMutableBytes({ raw in
        CGContext(
            data: raw.baseAddress,
            width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    }) else { return nil }

    // 深色径向渐变底（与 App 面板同系）。
    let colors = [
        CGColor(red: 0.118, green: 0.137, blue: 0.180, alpha: 1),
        CGColor(red: 0.055, green: 0.063, blue: 0.090, alpha: 1),
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1]) {
        ctx.drawRadialGradient(
            gradient,
            startCenter: CGPoint(x: pixelSize * 0.5, y: pixelSize * 0.56),
            startRadius: 0,
            endCenter: CGPoint(x: pixelSize * 0.5, y: pixelSize * 0.5),
            endRadius: pixelSize * 0.72,
            options: []
        )
    }

    let center = CGPoint(x: pixelSize * 0.5, y: pixelSize * 0.5)
    let lineWidth = pixelSize * 0.088
    // 由外到内三环；半径与线宽留出间隙。
    let radii: [CGFloat] = [0.336, 0.234, 0.132]
    ctx.setLineWidth(lineWidth)
    ctx.setLineCap(.round)

    for (index, radius) in radii.enumerated() {
        let r = pixelSize * radius
        // 背景轨道（低透明度同色）。
        let trackRect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
        ctx.setStrokeColor(red: 1, green: 1, blue: 1, alpha: 0.07)
        ctx.strokeEllipse(in: trackRect)
        // 活动弧：从 12 点方向顺时针。
        let fraction = ringFractions[index]
        ctx.setStrokeColor(ringColors[index])
        let start = CGFloat.pi / 2
        let end = start - fraction * 2 * .pi
        ctx.addArc(
            center: center, radius: r,
            startAngle: start, endAngle: end,
            clockwise: true
        )
        ctx.strokePath()
    }

    // 中心点：与最内环同色的实心小圆，形成表盘感。
    let dotRadius = pixelSize * 0.042
    let dotRect = CGRect(
        x: center.x - dotRadius, y: center.y - dotRadius,
        width: dotRadius * 2, height: dotRadius * 2
    )
    ctx.setFillColor(ringColors[2])
    ctx.fillEllipse(in: dotRect)

    guard let image = ctx.makeImage() else { return nil }
    let rep = NSBitmapImageRep(cgImage: image)
    return rep.representation(using: .png, properties: [:])
}

let iconsetURL = URL(fileURLWithPath: "Resources/QuotaBar.iconset")
try? FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let entries: [(String, CGFloat)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]
for (name, pixel) in entries {
    guard let data = drawIcon(pixelSize: pixel) else {
        FileHandle.standardError.write("draw failed: \(name)\n".data(using: .utf8)!)
        exit(1)
    }
    try data.write(to: iconsetURL.appendingPathComponent(name))
}
print("iconset written: \(iconsetURL.path)")
