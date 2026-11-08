import Foundation
import AppKit

func generateIcon() {
    let size = 1024
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return
    }

    // Outer squircle background
    let margin: CGFloat = 80
    let squircleRect = CGRect(x: margin, y: margin, width: CGFloat(size) - 2 * margin, height: CGFloat(size) - 2 * margin)
    let cornerRadius: CGFloat = 190
    let path = CGPath(roundedRect: squircleRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -20), blur: 40, color: NSColor.black.withAlphaComponent(0.4).cgColor)
    ctx.addPath(path)
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Background Gradient (Deep violet to vibrant magenta / coral)
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()

    let colors = [
        NSColor(red: 0.12, green: 0.10, blue: 0.30, alpha: 1.0).cgColor,
        NSColor(red: 0.45, green: 0.12, blue: 0.55, alpha: 1.0).cgColor,
        NSColor(red: 0.88, green: 0.20, blue: 0.45, alpha: 1.0).cgColor
    ] as CFArray
    let locations: [CGFloat] = [0.0, 0.55, 1.0]
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 512, y: 944), end: CGPoint(x: 512, y: 80), options: [])
    }

    // Subtle vinyl rings
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.06).cgColor)
    ctx.setLineWidth(2)
    for r in stride(from: 140, to: 380, by: 45) {
        ctx.strokeEllipse(in: CGRect(x: 512 - r, y: 512 - r, width: r * 2, height: r * 2))
    }

    // Draw Music Note Symbol
    let config = NSImage.SymbolConfiguration(pointSize: 420, weight: .bold)
    if let noteImg = NSImage(systemSymbolName: "music.note", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
        let noteRect = CGRect(x: 300, y: 300, width: 424, height: 424)
        // Draw note shadow
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 24, color: NSColor.black.withAlphaComponent(0.5).cgColor)
        noteImg.draw(in: noteRect)
        ctx.restoreGState()

        // White tinted note
        ctx.saveGState()
        ctx.setBlendMode(.sourceAtop)
        NSColor.white.setFill()
        ctx.fill(noteRect)
        ctx.restoreGState()
    }

    // Inner subtle glow border
    ctx.addPath(path)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.2).cgColor)
    ctx.setLineWidth(4)
    ctx.strokePath()

    ctx.restoreGState()
    image.unlockFocus()

    // Export to iconset
    let fileManager = FileManager.default
    let iconsetURL = URL(fileURLWithPath: "AppIcon.iconset")
    try? fileManager.removeItem(at: iconsetURL)
    try? fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

    let sizes: [(Int, Int, String)] = [
        (16, 1, "icon_16x16.png"),
        (16, 2, "icon_16x16@2x.png"),
        (32, 1, "icon_32x32.png"),
        (32, 2, "icon_32x32@2x.png"),
        (128, 1, "icon_128x128.png"),
        (128, 2, "icon_128x128@2x.png"),
        (256, 1, "icon_256x256.png"),
        (256, 2, "icon_256x256@2x.png"),
        (512, 1, "icon_512x512.png"),
        (512, 2, "icon_512x512@2x.png")
    ]

    for (pt, scale, name) in sizes {
        let px = pt * scale
        let targetRect = NSRect(x: 0, y: 0, width: px, height: px)
        let scaled = NSImage(size: NSSize(width: px, height: px))
        scaled.lockFocus()
        image.draw(in: targetRect, from: rect, operation: .copy, fraction: 1.0)
        scaled.unlockFocus()

        if let tiff = scaled.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            let fileURL = iconsetURL.appendingPathComponent(name)
            try? png.write(to: fileURL)
        }
    }

    print("Iconset generated at AppIcon.iconset")
}

generateIcon()
