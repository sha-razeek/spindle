import Foundation
import AppKit

func generateGramophoneIcon() {
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

    // Outer shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -24), blur: 44, color: NSColor.black.withAlphaComponent(0.55).cgColor)
    ctx.addPath(squirclePath)
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Clip to squircle
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()

    // Background: Deep dark studio gradient (rich dark charcoal / midnight bronze vignette)
    let bgColors = [
        NSColor(red: 0.16, green: 0.14, blue: 0.18, alpha: 1.0).cgColor,
        NSColor(red: 0.08, green: 0.07, blue: 0.10, alpha: 1.0).cgColor,
        NSColor(red: 0.04, green: 0.03, blue: 0.05, alpha: 1.0).cgColor
    ] as CFArray
    let bgLocations: [CGFloat] = [0.0, 0.6, 1.0]
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
        ctx.drawRadialGradient(
            bgGradient,
            startCenter: CGPoint(x: 512, y: 650),
            startRadius: 50,
            endCenter: CGPoint(x: 512, y: 512),
            endRadius: 600,
            options: [.drawsAfterEndLocation, .drawsBeforeStartLocation]
        )
    }

    // MARK: - 1. Wooden Cabinet Base
    let cabinetWidth: CGFloat = 460
    let cabinetHeight: CGFloat = 170
    let cabinetX: CGFloat = 512 - cabinetWidth / 2
    let cabinetY: CGFloat = 180

    // Cabinet shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 30, color: NSColor.black.withAlphaComponent(0.6).cgColor)
    let cabRect = CGRect(x: cabinetX, y: cabinetY, width: cabinetWidth, height: cabinetHeight)
    let cabPath = CGPath(roundedRect: cabRect, cornerWidth: 16, cornerHeight: 16, transform: nil)
    ctx.addPath(cabPath)
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Rich Mahogany Wood Box
    ctx.saveGState()
    ctx.addPath(cabPath)
    ctx.clip()

    let woodColors = [
        NSColor(red: 0.42, green: 0.18, blue: 0.10, alpha: 1.0).cgColor,
        NSColor(red: 0.28, green: 0.11, blue: 0.06, alpha: 1.0).cgColor,
        NSColor(red: 0.16, green: 0.06, blue: 0.03, alpha: 1.0).cgColor
    ] as CFArray
    if let woodGrad = CGGradient(colorsSpace: colorSpace, colors: woodColors, locations: [0.0, 0.5, 1.0]) {
        ctx.drawLinearGradient(woodGrad, start: CGPoint(x: cabinetX, y: cabinetY + cabinetHeight), end: CGPoint(x: cabinetX, y: cabinetY), options: [])
    }

    // Wood Grain lines
    ctx.setStrokeColor(NSColor(red: 0.50, green: 0.22, blue: 0.12, alpha: 0.25).cgColor)
    ctx.setLineWidth(2)
    for y in stride(from: cabinetY + 8, to: cabinetY + cabinetHeight - 8, by: 12) {
        ctx.move(to: CGPoint(x: cabinetX + 10, y: y))
        ctx.addCurve(
            to: CGPoint(x: cabinetX + cabinetWidth - 10, y: y + 2),
            control1: CGPoint(x: cabinetX + 160, y: y + 6),
            control2: CGPoint(x: cabinetX + 320, y: y - 4)
        )
        ctx.strokePath()
    }

    // Brass Plinth Trim along bottom of cabinet
    let brassTrimRect = CGRect(x: cabinetX + 12, y: cabinetY + 8, width: cabinetWidth - 24, height: 14)
    let brassTrimPath = CGPath(roundedRect: brassTrimRect, cornerWidth: 3, cornerHeight: 3, transform: nil)
    let brassColors = [
        NSColor(red: 0.95, green: 0.82, blue: 0.45, alpha: 1.0).cgColor,
        NSColor(red: 0.65, green: 0.45, blue: 0.18, alpha: 1.0).cgColor,
        NSColor(red: 0.90, green: 0.78, blue: 0.40, alpha: 1.0).cgColor
    ] as CFArray
    if let brassGrad = CGGradient(colorsSpace: colorSpace, colors: brassColors, locations: [0.0, 0.5, 1.0]) {
        ctx.saveGState()
        ctx.addPath(brassTrimPath)
        ctx.clip()
        ctx.drawLinearGradient(brassGrad, start: CGPoint(x: cabinetX, y: cabinetY + 22), end: CGPoint(x: cabinetX, y: cabinetY + 8), options: [])
        ctx.restoreGState()
    }

    // Top Cabinet Beveled Molding
    let topBevelRect = CGRect(x: cabinetX - 8, y: cabinetY + cabinetHeight - 16, width: cabinetWidth + 16, height: 16)
    let topBevelPath = CGPath(roundedRect: topBevelRect, cornerWidth: 4, cornerHeight: 4, transform: nil)
    ctx.restoreGState() // Exit cabinet clip

    ctx.saveGState()
    ctx.addPath(topBevelPath)
    ctx.setFillColor(NSColor(red: 0.35, green: 0.15, blue: 0.08, alpha: 1.0).cgColor)
    ctx.fillPath()
    // Highlight on top molding edge
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.25).cgColor)
    ctx.setLineWidth(1.5)
    ctx.move(to: CGPoint(x: cabinetX - 6, y: cabinetY + cabinetHeight))
    ctx.addLine(to: CGPoint(x: cabinetX + cabinetWidth + 6, y: cabinetY + cabinetHeight))
    ctx.strokePath()
    ctx.restoreGState()

    // Brass corner brackets on cabinet
    func drawBrassCorner(at x: CGFloat, y: CGFloat, flip: Bool) {
        ctx.saveGState()
        let w: CGFloat = 24
        let h: CGFloat = 24
        let path = CGMutablePath()
        path.move(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x + (flip ? -w : w), y: y))
        path.addLine(to: CGPoint(x: x + (flip ? -w : w), y: y + 8))
        path.addLine(to: CGPoint(x: x + (flip ? -8 : 8), y: y + 8))
        path.addLine(to: CGPoint(x: x + (flip ? -8 : 8), y: y + h))
        path.addLine(to: CGPoint(x: x, y: y + h))
        path.closeSubpath()
        ctx.addPath(path)
        ctx.setFillColor(NSColor(red: 0.85, green: 0.68, blue: 0.32, alpha: 1.0).cgColor)
        ctx.fillPath()
        ctx.restoreGState()
    }
    drawBrassCorner(at: cabinetX + 4, y: cabinetY + 4, flip: false)
    drawBrassCorner(at: cabinetX + cabinetWidth - 4, y: cabinetY + 4, flip: true)

    // MARK: - 2. Turntable Platter & Vinyl Record
    let platterCenterX: CGFloat = 430
    let platterCenterY: CGFloat = 360
    let platterRadiusX: CGFloat = 160
    let platterRadiusY: CGFloat = 55

    // Platter Rim (Metallic edge)
    ctx.saveGState()
    let platterRect = CGRect(x: platterCenterX - platterRadiusX, y: platterCenterY - platterRadiusY - 8, width: platterRadiusX * 2, height: platterRadiusY * 2 + 10)
    ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 16, color: NSColor.black.withAlphaComponent(0.5).cgColor)
    ctx.addEllipse(in: platterRect)
    ctx.setFillColor(NSColor(red: 0.45, green: 0.35, blue: 0.20, alpha: 1.0).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Black Vinyl Record on Platter
    ctx.saveGState()
    let vinylRect = CGRect(x: platterCenterX - platterRadiusX + 6, y: platterCenterY - platterRadiusY + 2, width: (platterRadiusX - 6) * 2, height: (platterRadiusY - 2) * 2)
    ctx.addEllipse(in: vinylRect)
    ctx.setFillColor(NSColor(white: 0.08, alpha: 1.0).cgColor)
    ctx.fillPath()

    // Concentric vinyl groove highlights on the ellipse
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.06).cgColor)
    ctx.setLineWidth(1)
    for f: CGFloat in [0.85, 0.72, 0.60, 0.48] {
        let rX = (platterRadiusX - 6) * f
        let rY = (platterRadiusY - 2) * f
        ctx.strokeEllipse(in: CGRect(x: platterCenterX - rX, y: platterCenterY - rY, width: rX * 2, height: rY * 2))
    }

    // Red Vintage Label in center of vinyl
    let labelRX = (platterRadiusX - 6) * 0.30
    let labelRY = (platterRadiusY - 2) * 0.30
    let labelRect = CGRect(x: platterCenterX - labelRX, y: platterCenterY - labelRY, width: labelRX * 2, height: labelRY * 2)
    ctx.addEllipse(in: labelRect)
    ctx.setFillColor(NSColor(red: 0.75, green: 0.18, blue: 0.15, alpha: 1.0).cgColor)
    ctx.fillPath()

    // Gold spindle pin
    ctx.addEllipse(in: CGRect(x: platterCenterX - 4, y: platterCenterY - 3, width: 8, height: 6))
    ctx.setFillColor(NSColor(red: 0.95, green: 0.85, blue: 0.45, alpha: 1.0).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // MARK: - 3. Tone Arm & Soundbox
    ctx.saveGState()
    // Tone arm bracket on right of deck
    let bracketX: CGFloat = 630
    let bracketY: CGFloat = 360
    ctx.addEllipse(in: CGRect(x: bracketX - 16, y: bracketY - 12, width: 32, height: 24))
    ctx.setFillColor(NSColor(red: 0.80, green: 0.62, blue: 0.28, alpha: 1.0).cgColor)
    ctx.fillPath()

    // Brass curved pipe from bracket to vinyl
    let toneArmPath = CGMutablePath()
    toneArmPath.move(to: CGPoint(x: bracketX, y: bracketY + 6))
    toneArmPath.addCurve(
        to: CGPoint(x: 480, y: 365),
        control1: CGPoint(x: 620, y: 410),
        control2: CGPoint(x: 540, y: 415)
    )
    ctx.addPath(toneArmPath)
    ctx.setStrokeColor(NSColor(red: 0.88, green: 0.72, blue: 0.35, alpha: 1.0).cgColor)
    ctx.setLineWidth(8)
    ctx.setLineCap(.round)
    ctx.strokePath()

    // Soundbox / Reproducer head
    let soundboxRect = CGRect(x: 464, y: 350, width: 28, height: 28)
    ctx.addEllipse(in: soundboxRect)
    ctx.setFillColor(NSColor(red: 0.65, green: 0.50, blue: 0.25, alpha: 1.0).cgColor)
    ctx.fillPath()
    ctx.setStrokeColor(NSColor(red: 0.95, green: 0.85, blue: 0.45, alpha: 1.0).cgColor)
    ctx.setLineWidth(2)
    ctx.strokeEllipse(in: soundboxRect)
    ctx.restoreGState()

    // MARK: - 4. The Iconic Fluted Brass Gramophone Horn
    // The acoustic horn base / elbow tube connects from back right, sweeps up and flares outward to top-center!
    let elbowPath = CGMutablePath()
    elbowPath.move(to: CGPoint(x: bracketX - 10, y: bracketY + 12))
    elbowPath.addCurve(
        to: CGPoint(x: 540, y: 520),
        control1: CGPoint(x: 660, y: 440),
        control2: CGPoint(x: 630, y: 500)
    )
    ctx.saveGState()
    ctx.addPath(elbowPath)
    ctx.setStrokeColor(NSColor(red: 0.82, green: 0.65, blue: 0.30, alpha: 1.0).cgColor)
    ctx.setLineWidth(24)
    ctx.setLineCap(.round)
    ctx.strokePath()
    ctx.restoreGState()

    // Horn Flare / Bell Body
    // The horn body expands upwards from (540, 520) into a grand fluted bell centered around (500, 720)
    let bellCenterX: CGFloat = 520
    let bellCenterY: CGFloat = 720
    let bellRadiusX: CGFloat = 260
    let bellRadiusY: CGFloat = 190

    // Horn Shadow casting downward onto cabinet
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: -20, height: -35), blur: 50, color: NSColor.black.withAlphaComponent(0.65).cgColor)
    let hornBodyPath = CGMutablePath()
    hornBodyPath.move(to: CGPoint(x: 525, y: 515))
    hornBodyPath.addQuadCurve(to: CGPoint(x: bellCenterX - bellRadiusX + 20, y: bellCenterY - 10), control: CGPoint(x: 400, y: 550))
    hornBodyPath.addQuadCurve(to: CGPoint(x: bellCenterX + bellRadiusX - 10, y: bellCenterY + 40), control: CGPoint(x: bellCenterX, y: bellCenterY + bellRadiusY))
    hornBodyPath.addQuadCurve(to: CGPoint(x: 555, y: 525), control: CGPoint(x: 630, y: 590))
    hornBodyPath.closeSubpath()
    ctx.addPath(hornBodyPath)
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Draw Horn Outer Bell
    ctx.saveGState()
    let bellOuterRect = CGRect(x: bellCenterX - bellRadiusX, y: bellCenterY - bellRadiusY, width: bellRadiusX * 2, height: bellRadiusY * 2)
    let bellOuterPath = CGPath(ellipseIn: bellOuterRect, transform: nil)

    // Horn Flare Body Gradient (Burnished Polished Brass)
    let brassColorsRich = [
        NSColor(red: 0.98, green: 0.90, blue: 0.60, alpha: 1.0).cgColor, // Bright Gold Specular
        NSColor(red: 0.88, green: 0.70, blue: 0.32, alpha: 1.0).cgColor, // Polished Brass
        NSColor(red: 0.68, green: 0.48, blue: 0.18, alpha: 1.0).cgColor, // Warm Bronze
        NSColor(red: 0.45, green: 0.28, blue: 0.08, alpha: 1.0).cgColor, // Deep Shadow
        NSColor(red: 0.92, green: 0.78, blue: 0.42, alpha: 1.0).cgColor  // Rim reflection
    ] as CFArray
    let brassLocationsRich: [CGFloat] = [0.0, 0.25, 0.55, 0.85, 1.0]

    if let hornGrad = CGGradient(colorsSpace: colorSpace, colors: brassColorsRich, locations: brassLocationsRich) {
        ctx.addPath(hornBodyPath)
        ctx.clip()
        ctx.drawLinearGradient(hornGrad, start: CGPoint(x: 350, y: 780), end: CGPoint(x: 650, y: 480), options: [])
    }
    ctx.restoreGState()

    // MARK: - 5. Fluted Petals of the Bell Horn
    // A gramophone horn has distinct petal segments / flutes (usually 10-12 flutes)
    ctx.saveGState()
    let petalCount = 12
    let angleStep = (CGFloat.pi * 2) / CGFloat(petalCount)

    // Outer scalloped bell rim
    let scallopedPath = CGMutablePath()
    for i in 0..<petalCount {
        let a1 = CGFloat(i) * angleStep
        let a2 = CGFloat(i + 1) * angleStep
        let aMid = (a1 + a2) / 2

        let rX = bellRadiusX
        let rY = bellRadiusY
        let rXOuter = bellRadiusX + 16
        let rYOuter = bellRadiusY + 14

        let p1 = CGPoint(x: bellCenterX + cos(a1) * rX, y: bellCenterY + sin(a1) * rY)
        let pMid = CGPoint(x: bellCenterX + cos(aMid) * rXOuter, y: bellCenterY + sin(aMid) * rYOuter)
        let p2 = CGPoint(x: bellCenterX + cos(a2) * rX, y: bellCenterY + sin(a2) * rY)

        if i == 0 {
            scallopedPath.move(to: p1)
        }
        scallopedPath.addQuadCurve(to: p2, control: pMid)
    }
    scallopedPath.closeSubpath()

    // Fill Scalloped Rim with Gold
    ctx.saveGState()
    ctx.addPath(scallopedPath)
    ctx.setFillColor(NSColor(red: 0.86, green: 0.68, blue: 0.30, alpha: 1.0).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // Inner Bell Cavern / Throat (Deep dark void inside the horn)
    let throatRadiusX: CGFloat = bellRadiusX * 0.72
    let throatRadiusY: CGFloat = bellRadiusY * 0.70
    let throatRect = CGRect(x: bellCenterX - throatRadiusX + 10, y: bellCenterY - throatRadiusY - 10, width: throatRadiusX * 2, height: throatRadiusY * 2)

    let innerCavernColors = [
        NSColor(red: 0.05, green: 0.03, blue: 0.02, alpha: 1.0).cgColor,
        NSColor(red: 0.18, green: 0.10, blue: 0.04, alpha: 1.0).cgColor,
        NSColor(red: 0.40, green: 0.25, blue: 0.10, alpha: 1.0).cgColor
    ] as CFArray
    if let throatGrad = CGGradient(colorsSpace: colorSpace, colors: innerCavernColors, locations: [0.0, 0.65, 1.0]) {
        ctx.saveGState()
        ctx.addEllipse(in: throatRect)
        ctx.clip()
        ctx.drawRadialGradient(
            throatGrad,
            startCenter: CGPoint(x: bellCenterX + 15, y: bellCenterY - 15),
            startRadius: 20,
            endCenter: CGPoint(x: bellCenterX + 10, y: bellCenterY - 10),
            endRadius: throatRadiusX,
            options: [.drawsAfterEndLocation, .drawsBeforeStartLocation]
        )
        ctx.restoreGState()
    }

    // Fluted Ridges (Lines emanating from throat to scalloped rim)
    ctx.saveGState()
    for i in 0..<petalCount {
        let a = CGFloat(i) * angleStep
        let pThroat = CGPoint(x: bellCenterX + 10 + cos(a) * throatRadiusX * 0.85, y: bellCenterY - 10 + sin(a) * throatRadiusY * 0.85)
        let pRim = CGPoint(x: bellCenterX + cos(a) * (bellRadiusX + 8), y: bellCenterY + sin(a) * (bellRadiusY + 8))

        // Highlight ridge
        ctx.setStrokeColor(NSColor(red: 1.0, green: 0.94, blue: 0.75, alpha: 0.55).cgColor)
        ctx.setLineWidth(3)
        ctx.move(to: pThroat)
        ctx.addLine(to: pRim)
        ctx.strokePath()

        // Shadow groove next to ridge
        let aShadow = a + 0.05
        let pThroatS = CGPoint(x: bellCenterX + 10 + cos(aShadow) * throatRadiusX * 0.85, y: bellCenterY - 10 + sin(aShadow) * throatRadiusY * 0.85)
        let pRimS = CGPoint(x: bellCenterX + cos(aShadow) * (bellRadiusX + 6), y: bellCenterY + sin(aShadow) * (bellRadiusY + 6))
        ctx.setStrokeColor(NSColor(red: 0.35, green: 0.20, blue: 0.05, alpha: 0.45).cgColor)
        ctx.setLineWidth(2)
        ctx.move(to: pThroatS)
        ctx.addLine(to: pRimS)
        ctx.strokePath()
    }
    ctx.restoreGState()

    // Brilliant Specular Rim Highlight around top-left of horn
    ctx.saveGState()
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.85).cgColor)
    ctx.setLineWidth(4)
    let rimHighlightPath = CGMutablePath()
    rimHighlightPath.addArc(
        center: CGPoint(x: bellCenterX, y: bellCenterY),
        radius: bellRadiusX + 8,
        startAngle: CGFloat.pi * 0.65,
        endAngle: CGFloat.pi * 1.25,
        clockwise: false
    )
    ctx.addPath(rimHighlightPath)
    ctx.strokePath()
    ctx.restoreGState()

    // Inner subtle glow border for squircle
    ctx.restoreGState() // Exit squircle clip
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.18).cgColor)
    ctx.setLineWidth(3.5)
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

    print("Gramophone Iconset generated at AppIcon.iconset")
}

generateGramophoneIcon()
