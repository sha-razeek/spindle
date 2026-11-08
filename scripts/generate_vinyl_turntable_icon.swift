import Foundation
import AppKit

func generateVinylTurntableIcon() {
    let size = 1024
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return
    }

    let colorSpace = CGColorSpaceCreateDeviceRGB()

    // MARK: - 1. Canvas Squircle Base (macOS Icon Standard)
    let margin: CGFloat = 82
    let squircleRect = CGRect(x: margin, y: margin, width: CGFloat(size) - 2 * margin, height: CGFloat(size) - 2 * margin)
    let cornerRadius: CGFloat = 190
    let squirclePath = CGPath(roundedRect: squircleRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Outer Icon Drop Shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -20), blur: 38, color: NSColor.black.withAlphaComponent(0.24).cgColor)
    ctx.addPath(squirclePath)
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Clip to Squircle
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()

    // Turntable Plinth Surface Gradient (Clean Studio Light / Soft Warm Slate White)
    let plinthColors = [
        NSColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0).cgColor,
        NSColor(red: 0.93, green: 0.94, blue: 0.95, alpha: 1.0).cgColor,
        NSColor(red: 0.88, green: 0.89, blue: 0.91, alpha: 1.0).cgColor
    ] as CFArray
    if let plinthGrad = CGGradient(colorsSpace: colorSpace, colors: plinthColors, locations: [0.0, 0.65, 1.0]) {
        ctx.drawLinearGradient(plinthGrad, start: CGPoint(x: 512, y: 942), end: CGPoint(x: 512, y: 82), options: [])
    }

    // Subtle brushed plinth texture / rim
    ctx.saveGState()
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.8).cgColor)
    ctx.setLineWidth(2)
    ctx.addPath(squirclePath)
    ctx.strokePath()
    ctx.restoreGState()

    // MARK: - 2. Turntable Circular Platter Well (Recessed platter ring)
    let vinylCenter = CGPoint(x: 440, y: 512)
    let vinylRadius: CGFloat = 345

    // Outer Platter Well Shadow & Rim
    let platterWellRadius: CGFloat = vinylRadius + 14
    let platterWellRect = CGRect(x: vinylCenter.x - platterWellRadius, y: vinylCenter.y - platterWellRadius, width: platterWellRadius * 2, height: platterWellRadius * 2)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 18, color: NSColor.black.withAlphaComponent(0.18).cgColor)
    ctx.addEllipse(in: platterWellRect)
    ctx.setFillColor(NSColor(red: 0.18, green: 0.19, blue: 0.21, alpha: 1.0).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Platter Chamfer Beveled Ring
    let platterRimRect = CGRect(x: vinylCenter.x - vinylRadius - 4, y: vinylCenter.y - vinylRadius - 4, width: (vinylRadius + 4) * 2, height: (vinylRadius + 4) * 2)
    ctx.saveGState()
    ctx.addEllipse(in: platterRimRect)
    ctx.setFillColor(NSColor(red: 0.80, green: 0.82, blue: 0.84, alpha: 1.0).cgColor) // Machined silver edge
    ctx.fillPath()
    ctx.restoreGState()

    // MARK: - 3. Vinyl Disc Body (Top-Down View)
    let vinylRect = CGRect(x: vinylCenter.x - vinylRadius, y: vinylCenter.y - vinylRadius, width: vinylRadius * 2, height: vinylRadius * 2)

    // Cast shadow from vinyl onto platter
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 2, height: -12), blur: 24, color: NSColor.black.withAlphaComponent(0.45).cgColor)
    ctx.addEllipse(in: vinylRect)
    ctx.setFillColor(NSColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Vinyl Disc Surface Clipping for grooves and reflections
    ctx.saveGState()
    ctx.addEllipse(in: vinylRect)
    ctx.clip()

    // Vinyl Surface Base Gradient
    let discColors = [
        NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0).cgColor,
        NSColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1.0).cgColor
    ] as CFArray
    if let discGrad = CGGradient(colorsSpace: colorSpace, colors: discColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(
            discGrad,
            startCenter: vinylCenter,
            startRadius: 80,
            endCenter: vinylCenter,
            endRadius: vinylRadius,
            options: [.drawsAfterEndLocation, .drawsBeforeStartLocation]
        )
    }

    // Concentric Micro-Grooves (Fine vinyl sound rings)
    ctx.saveGState()
    for r in stride(from: vinylRadius * 0.40, through: vinylRadius * 0.94, by: 4.5) {
        ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.040).cgColor)
        ctx.setLineWidth(0.85)
        ctx.strokeEllipse(in: CGRect(x: vinylCenter.x - r, y: vinylCenter.y - r, width: r * 2, height: r * 2))
    }
    // Lead-in groove rim
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.12).cgColor)
    ctx.setLineWidth(1.6)
    ctx.strokeEllipse(in: CGRect(x: vinylCenter.x - vinylRadius * 0.96, y: vinylCenter.y - vinylRadius * 0.96, width: vinylRadius * 1.92, height: vinylRadius * 1.92))
    ctx.restoreGState()

    // Dual-Cone Specular Butterfly Sheen (Turntable reflection)
    // Draw 4 soft specular highlight wedges centered at vinylCenter
    let wedgeAngles: [CGFloat] = [
        .pi * 0.20,  // ~36 deg
        .pi * 0.70,  // ~126 deg
        .pi * 1.20,  // ~216 deg
        .pi * 1.70   // ~306 deg
    ]
    for angle in wedgeAngles {
        ctx.saveGState()
        let sheenPath = CGMutablePath()
        sheenPath.move(to: vinylCenter)
        sheenPath.addArc(center: vinylCenter, radius: vinylRadius, startAngle: angle - 0.28, endAngle: angle + 0.28, clockwise: false)
        sheenPath.closeSubpath()
        ctx.addPath(sheenPath)

        let sheenColors = [
            NSColor.white.withAlphaComponent(0.18).cgColor,
            NSColor.white.withAlphaComponent(0.03).cgColor,
            NSColor.clear.cgColor
        ] as CFArray
        if let sheenGrad = CGGradient(colorsSpace: colorSpace, colors: sheenColors, locations: [0.0, 0.7, 1.0]) {
            let endPt = CGPoint(x: vinylCenter.x + cos(angle) * vinylRadius, y: vinylCenter.y + sin(angle) * vinylRadius)
            ctx.drawLinearGradient(sheenGrad, start: vinylCenter, end: endPt, options: [])
        }
        ctx.restoreGState()
    }

    // Lead-out run-out smooth ring
    let runOutRadius: CGFloat = vinylRadius * 0.38
    ctx.addEllipse(in: CGRect(x: vinylCenter.x - runOutRadius, y: vinylCenter.y - runOutRadius, width: runOutRadius * 2, height: runOutRadius * 2))
    ctx.setFillColor(NSColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0).cgColor)
    ctx.fillPath()

    // MARK: - 4. Center Paper Label (Warm Red-Orange / Amber Record Label)
    let labelRadius: CGFloat = vinylRadius * 0.33
    let labelRect = CGRect(x: vinylCenter.x - labelRadius, y: vinylCenter.y - labelRadius, width: labelRadius * 2, height: labelRadius * 2)

    let labelColors = [
        NSColor(red: 0.98, green: 0.38, blue: 0.24, alpha: 1.0).cgColor, // Vibrant Tangerine
        NSColor(red: 0.88, green: 0.22, blue: 0.14, alpha: 1.0).cgColor  // Rich Crimson
    ] as CFArray
    if let labelGrad = CGGradient(colorsSpace: colorSpace, colors: labelColors, locations: [0.0, 1.0]) {
        ctx.saveGState()
        ctx.addEllipse(in: labelRect)
        ctx.clip()
        ctx.drawLinearGradient(labelGrad, start: CGPoint(x: vinylCenter.x, y: vinylCenter.y + labelRadius), end: CGPoint(x: vinylCenter.x, y: vinylCenter.y - labelRadius), options: [])

        // Label concentric ring print
        ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.35).cgColor)
        ctx.setLineWidth(1.5)
        ctx.strokeEllipse(in: CGRect(x: vinylCenter.x - labelRadius * 0.75, y: vinylCenter.y - labelRadius * 0.75, width: labelRadius * 1.5, height: labelRadius * 1.5))

        // Center Spindle Hole
        let spindleRadius: CGFloat = 16
        ctx.addEllipse(in: CGRect(x: vinylCenter.x - spindleRadius, y: vinylCenter.y - spindleRadius, width: spindleRadius * 2, height: spindleRadius * 2))
        ctx.setFillColor(NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor)
        ctx.fillPath()

        // Chrome spindle pin ring
        ctx.setStrokeColor(NSColor(white: 0.92, alpha: 1.0).cgColor)
        ctx.setLineWidth(2.5)
        ctx.strokeEllipse(in: CGRect(x: vinylCenter.x - spindleRadius + 1, y: vinylCenter.y - spindleRadius + 1, width: (spindleRadius - 1) * 2, height: (spindleRadius - 1) * 2))

        ctx.restoreGState()
    }

    ctx.restoreGState() // Exit vinyl clip

    // MARK: - 5. Tonearm Assembly (Top-Down View)
    // Pivot Base at Top-Right
    let pivotCenter = CGPoint(x: 775, y: 730)
    let pivotBaseRadius: CGFloat = 62

    // Tonearm drop shadow onto vinyl and plinth
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: -10, height: -16), blur: 20, color: NSColor.black.withAlphaComponent(0.42).cgColor)

    // Tonearm Pivot Mount Housing (Brushed Metal Turret)
    ctx.addEllipse(in: CGRect(x: pivotCenter.x - pivotBaseRadius, y: pivotCenter.y - pivotBaseRadius, width: pivotBaseRadius * 2, height: pivotBaseRadius * 2))
    ctx.setFillColor(NSColor(red: 0.25, green: 0.26, blue: 0.28, alpha: 1.0).cgColor)
    ctx.fillPath()

    // Inner Chrome Gimbal Pivot Ring
    let gimbalRadius: CGFloat = pivotBaseRadius * 0.68
    ctx.addEllipse(in: CGRect(x: pivotCenter.x - gimbalRadius, y: pivotCenter.y - gimbalRadius, width: gimbalRadius * 2, height: gimbalRadius * 2))
    ctx.setFillColor(NSColor(red: 0.78, green: 0.80, blue: 0.82, alpha: 1.0).cgColor)
    ctx.fillPath()

    // Counterweight cylinder (extends backwards towards top-right)
    let cwPath = CGMutablePath()
    let cwAngle: CGFloat = .pi * 0.28
    let cwCenter = CGPoint(x: pivotCenter.x + cos(cwAngle) * 60, y: pivotCenter.y + sin(cwAngle) * 60)
    cwPath.addEllipse(in: CGRect(x: cwCenter.x - 24, y: cwCenter.y - 24, width: 48, height: 48))
    ctx.addPath(cwPath)
    ctx.setFillColor(NSColor(red: 0.18, green: 0.18, blue: 0.20, alpha: 1.0).cgColor)
    ctx.fillPath()

    // Tonearm Wand (Extends from pivot across the vinyl grooves)
    // Classic gentle S-curve / straight modern wand towards the needle on the record
    let needlePoint = CGPoint(x: 485, y: 310) // Tracking along outer-mid groove
    let wandPath = CGMutablePath()
    wandPath.move(to: pivotCenter)
    wandPath.addCurve(
        to: needlePoint,
        control1: CGPoint(x: 720, y: 560),
        control2: CGPoint(x: 610, y: 390)
    )

    // Wand Tube (Solid Brushed Aluminum)
    ctx.addPath(wandPath)
    ctx.setStrokeColor(NSColor(red: 0.88, green: 0.90, blue: 0.92, alpha: 1.0).cgColor)
    ctx.setLineWidth(14)
    ctx.setLineCap(.round)
    ctx.strokePath()

    // Headshell & Cartridge (Angled along the tangent of the groove)
    let cartridgePath = CGMutablePath()
    let headAngle: CGFloat = .pi * 0.70 // Tangent angle
    let headLen: CGFloat = 46
    let headWidth: CGFloat = 22
    let headTip = CGPoint(x: needlePoint.x - cos(headAngle) * (headLen * 0.5), y: needlePoint.y - sin(headAngle) * (headLen * 0.5))
    let headTail = CGPoint(x: needlePoint.x + cos(headAngle) * (headLen * 0.5), y: needlePoint.y + sin(headAngle) * (headLen * 0.5))

    let perpX = -sin(headAngle) * (headWidth * 0.5)
    let perpY = cos(headAngle) * (headWidth * 0.5)

    cartridgePath.move(to: CGPoint(x: headTail.x + perpX, y: headTail.y + perpY))
    cartridgePath.addLine(to: CGPoint(x: headTip.x + perpX, y: headTip.y + perpY))
    cartridgePath.addLine(to: CGPoint(x: headTip.x - perpX, y: headTip.y - perpY))
    cartridgePath.addLine(to: CGPoint(x: headTail.x - perpX, y: headTail.y - perpY))
    cartridgePath.closeSubpath()

    // Cartridge Body (Matte Black / Charcoal)
    ctx.addPath(cartridgePath)
    ctx.setFillColor(NSColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0).cgColor)
    ctx.fillPath()

    // Stylus / Needle Accent (Gold/Red needle tip indicator)
    ctx.addEllipse(in: CGRect(x: headTip.x - 4, y: headTip.y - 4, width: 8, height: 8))
    ctx.setFillColor(NSColor(red: 0.95, green: 0.75, blue: 0.25, alpha: 1.0).cgColor)
    ctx.fillPath()

    ctx.restoreGState() // Exit tonearm shadow

    // Headshell Top Bevel Highlight
    ctx.saveGState()
    ctx.addPath(cartridgePath)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.35).cgColor)
    ctx.setLineWidth(1.5)
    ctx.strokePath()

    // Tonearm Wand Top Specular Specular Line
    ctx.addPath(wandPath)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.85).cgColor)
    ctx.setLineWidth(3.0)
    ctx.setLineCap(.round)
    ctx.strokePath()

    // Pivot Center Metallic Cap
    ctx.addEllipse(in: CGRect(x: pivotCenter.x - 12, y: pivotCenter.y - 12, width: 24, height: 24))
    ctx.setFillColor(NSColor(red: 0.92, green: 0.93, blue: 0.95, alpha: 1.0).cgColor)
    ctx.fillPath()
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

    print("Vinyl Turntable Iconset generated successfully at AppIcon.iconset")
}

generateVinylTurntableIcon()
