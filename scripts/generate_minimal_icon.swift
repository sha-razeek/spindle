import Foundation
import AppKit

func generateMinimalGramophoneIcon() {
    let size = 1024
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return
    }

    // Canvas squircle
    let margin: CGFloat = 80
    let squircleRect = CGRect(x: margin, y: margin, width: CGFloat(size) - 2 * margin, height: CGFloat(size) - 2 * margin)
    let cornerRadius: CGFloat = 190
    let squirclePath = CGPath(roundedRect: squircleRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Outer subtle shadow for the macOS icon tile
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 36, color: NSColor.black.withAlphaComponent(0.22).cgColor)
    ctx.addPath(squirclePath)
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Clip to squircle
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()

    // Pure Clean White Background with ultra-subtle gradient
    let bgColors = [
        NSColor(white: 1.0, alpha: 1.0).cgColor,
        NSColor(white: 0.985, alpha: 1.0).cgColor,
        NSColor(white: 0.965, alpha: 1.0).cgColor
    ] as CFArray
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    if let bgGrad = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 0.7, 1.0]) {
        ctx.drawLinearGradient(bgGrad, start: CGPoint(x: 512, y: 944), end: CGPoint(x: 512, y: 80), options: [])
    }

    // Shadow cast by the whole gramophone onto the white background
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -24), blur: 40, color: NSColor(white: 0.0, alpha: 0.16).cgColor)

    // MARK: - Minimalist Turntable Base
    let baseX: CGFloat = 310
    let baseY: CGFloat = 260
    let baseWidth: CGFloat = 404
    let baseHeight: CGFloat = 100
    let baseRect = CGRect(x: baseX, y: baseY, width: baseWidth, height: baseHeight)
    let basePath = CGPath(roundedRect: baseRect, cornerWidth: 26, cornerHeight: 26, transform: nil)

    ctx.addPath(basePath)
    ctx.setFillColor(NSColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0).cgColor)
    ctx.fillPath()
    ctx.restoreGState() // Exit gramophone ground shadow

    // Base subtle surface gradient (Matte space grey / charcoal)
    ctx.saveGState()
    ctx.addPath(basePath)
    ctx.clip()
    let baseColors = [
        NSColor(red: 0.22, green: 0.22, blue: 0.25, alpha: 1.0).cgColor,
        NSColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1.0).cgColor
    ] as CFArray
    if let baseGrad = CGGradient(colorsSpace: colorSpace, colors: baseColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(baseGrad, start: CGPoint(x: baseX, y: baseY + baseHeight), end: CGPoint(x: baseX, y: baseY), options: [])
    }
    // Top highlight rim of the base
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.20).cgColor)
    ctx.setLineWidth(2)
    ctx.strokePath()
    ctx.restoreGState()

    // MARK: - Vinyl Record Platter on Base
    let vinylCenterX: CGFloat = 435
    let vinylCenterY: CGFloat = 345
    let vinylRadiusX: CGFloat = 135
    let vinylRadiusY: CGFloat = 46

    // Vinyl Record Ellipse
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 14, color: NSColor.black.withAlphaComponent(0.35).cgColor)
    let vinylRect = CGRect(x: vinylCenterX - vinylRadiusX, y: vinylCenterY - vinylRadiusY, width: vinylRadiusX * 2, height: vinylRadiusY * 2)
    ctx.addEllipse(in: vinylRect)
    ctx.setFillColor(NSColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Concentric grooves
    ctx.saveGState()
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.08).cgColor)
    ctx.setLineWidth(1.2)
    for f: CGFloat in [0.85, 0.70, 0.55] {
        let rx = vinylRadiusX * f
        let ry = vinylRadiusY * f
        ctx.strokeEllipse(in: CGRect(x: vinylCenterX - rx, y: vinylCenterY - ry, width: rx * 2, height: ry * 2))
    }

    // Minimal center label (Warm golden orange)
    let labelRx: CGFloat = vinylRadiusX * 0.32
    let labelRy: CGFloat = vinylRadiusY * 0.32
    ctx.addEllipse(in: CGRect(x: vinylCenterX - labelRx, y: vinylCenterY - labelRy, width: labelRx * 2, height: labelRy * 2))
    ctx.setFillColor(NSColor(red: 0.95, green: 0.60, blue: 0.20, alpha: 1.0).cgColor)
    ctx.fillPath()

    // Center spindle pin
    ctx.addEllipse(in: CGRect(x: vinylCenterX - 4, y: vinylCenterY - 3, width: 8, height: 6))
    ctx.setFillColor(NSColor(white: 0.95, alpha: 1.0).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // MARK: - Minimal Tone Arm
    ctx.saveGState()
    let toneArmPath = CGMutablePath()
    toneArmPath.move(to: CGPoint(x: 620, y: 335))
    toneArmPath.addCurve(
        to: CGPoint(x: 480, y: 350),
        control1: CGPoint(x: 610, y: 380),
        control2: CGPoint(x: 540, y: 385)
    )
    ctx.addPath(toneArmPath)
    ctx.setStrokeColor(NSColor(red: 0.85, green: 0.72, blue: 0.40, alpha: 1.0).cgColor)
    ctx.setLineWidth(5)
    ctx.setLineCap(.round)
    ctx.strokePath()

    // Tone arm pivot dot
    ctx.addEllipse(in: CGRect(x: 613, y: 328, width: 14, height: 14))
    ctx.setFillColor(NSColor(red: 0.75, green: 0.62, blue: 0.35, alpha: 1.0).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // MARK: - Minimal Elegant Gramophone Brass Horn
    // Originates from tone pipe, swoops up and flares into a modern minimal golden bell
    let hornTubePath = CGMutablePath()
    hornTubePath.move(to: CGPoint(x: 605, y: 345))
    hornTubePath.addCurve(
        to: CGPoint(x: 530, y: 530),
        control1: CGPoint(x: 660, y: 400),
        control2: CGPoint(x: 620, y: 490)
    )
    ctx.saveGState()
    ctx.addPath(hornTubePath)
    ctx.setStrokeColor(NSColor(red: 0.82, green: 0.65, blue: 0.28, alpha: 1.0).cgColor)
    ctx.setLineWidth(16)
    ctx.setLineCap(.round)
    ctx.strokePath()
    ctx.restoreGState()

    // Large Minimal Horn Flare (Bell)
    let bellCenter = CGPoint(x: 505, y: 690)
    let bellRadiusX: CGFloat = 225
    let bellRadiusY: CGFloat = 175

    // Horn body cone connecting tube to bell
    let hornConePath = CGMutablePath()
    hornConePath.move(to: CGPoint(x: 518, y: 525))
    hornConePath.addQuadCurve(to: CGPoint(x: bellCenter.x - bellRadiusX + 25, y: bellCenter.y - 10), control: CGPoint(x: 410, y: 550))
    hornConePath.addQuadCurve(to: CGPoint(x: bellCenter.x + bellRadiusX - 15, y: bellCenter.y + 20), control: CGPoint(x: bellCenter.x, y: bellCenter.y + bellRadiusY))
    hornConePath.addQuadCurve(to: CGPoint(x: 542, y: 535), control: CGPoint(x: 610, y: 580))
    hornConePath.closeSubpath()

    // Horn Shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: -12, height: -28), blur: 36, color: NSColor(white: 0.0, alpha: 0.22).cgColor)
    ctx.addPath(hornConePath)
    ctx.setFillColor(NSColor(red: 0.85, green: 0.68, blue: 0.28, alpha: 1.0).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Horn Cone Gradient (Clean Satin Gold)
    ctx.saveGState()
    ctx.addPath(hornConePath)
    ctx.clip()
    let hornColors = [
        NSColor(red: 0.98, green: 0.86, blue: 0.48, alpha: 1.0).cgColor, // Bright Gold
        NSColor(red: 0.90, green: 0.70, blue: 0.28, alpha: 1.0).cgColor, // Warm Gold
        NSColor(red: 0.72, green: 0.50, blue: 0.16, alpha: 1.0).cgColor  // Bronze Shadow
    ] as CFArray
    if let hornGrad = CGGradient(colorsSpace: colorSpace, colors: hornColors, locations: [0.0, 0.45, 1.0]) {
        ctx.drawLinearGradient(hornGrad, start: CGPoint(x: 370, y: 760), end: CGPoint(x: 610, y: 510), options: [])
    }
    ctx.restoreGState()

    // Minimal Bell Outer Rim Ellipse
    let bellRect = CGRect(x: bellCenter.x - bellRadiusX, y: bellCenter.y - bellRadiusY, width: bellRadiusX * 2, height: bellRadiusY * 2)
    ctx.saveGState()
    ctx.addEllipse(in: bellRect)
    ctx.setFillColor(NSColor(red: 0.92, green: 0.74, blue: 0.32, alpha: 1.0).cgColor)
    ctx.fillPath()

    // Inner Bell Throat (Minimalist Deep Oval)
    let throatRadiusX: CGFloat = bellRadiusX * 0.74
    let throatRadiusY: CGFloat = bellRadiusY * 0.72
    let throatRect = CGRect(x: bellCenter.x - throatRadiusX + 8, y: bellCenter.y - throatRadiusY - 8, width: throatRadiusX * 2, height: throatRadiusY * 2)

    let throatColors = [
        NSColor(red: 0.10, green: 0.07, blue: 0.04, alpha: 1.0).cgColor,
        NSColor(red: 0.24, green: 0.16, blue: 0.06, alpha: 1.0).cgColor,
        NSColor(red: 0.50, green: 0.35, blue: 0.12, alpha: 1.0).cgColor
    ] as CFArray
    if let throatGrad = CGGradient(colorsSpace: colorSpace, colors: throatColors, locations: [0.0, 0.6, 1.0]) {
        ctx.saveGState()
        ctx.addEllipse(in: throatRect)
        ctx.clip()
        ctx.drawRadialGradient(
            throatGrad,
            startCenter: CGPoint(x: bellCenter.x + 10, y: bellCenter.y - 12),
            startRadius: 15,
            endCenter: CGPoint(x: bellCenter.x + 8, y: bellCenter.y - 8),
            endRadius: throatRadiusX,
            options: [.drawsAfterEndLocation, .drawsBeforeStartLocation]
        )
        ctx.restoreGState()
    }

    // Modern Minimal Gold Rim Highlight Ring
    ctx.setStrokeColor(NSColor(red: 1.0, green: 0.94, blue: 0.72, alpha: 0.85).cgColor)
    ctx.setLineWidth(4.5)
    ctx.strokeEllipse(in: bellRect)
    ctx.restoreGState()

    // Inner subtle 1px border for squircle frame
    ctx.restoreGState() // Exit squircle clip
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.setStrokeColor(NSColor(white: 0.0, alpha: 0.08).cgColor)
    ctx.setLineWidth(2)
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
        image.draw(in: targetRect, from: NSRect(x: 0, y: 0, width: size, height: size), operation: .copy, fraction: 1.0)
        scaled.unlockFocus()

        if let tiff = scaled.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            let fileURL = iconsetURL.appendingPathComponent(name)
            try? png.write(to: fileURL)
        }
    }

    print("Minimal Gramophone Iconset generated at AppIcon.iconset")
}

generateMinimalGramophoneIcon()
