import AppKit

let sizes = [16, 32, 64, 128, 256, 512, 1024]
let outputDir = URL(fileURLWithPath: "AppIcon.iconset", isDirectory: true)
try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

func drawIcon(size: NSSize) -> NSImage {
    let image = NSImage(size: size)
    image.lockFocus()

    let rect = NSRect(origin: .zero, size: size)
    let cornerRadius = size.width * 0.22
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    path.addClip()

    // Gradient background
    let gradient = NSGradient(starting: NSColor(red: 0.15, green: 0.35, blue: 0.75, alpha: 1),
                              ending: NSColor(red: 0.45, green: 0.20, blue: 0.65, alpha: 1))
    gradient?.draw(in: rect, angle: -45)

    // Inner shadow border
    let innerPath = NSBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 2), xRadius: cornerRadius - 2, yRadius: cornerRadius - 2)
    NSColor(white: 1, alpha: 0.08).setStroke()
    innerPath.lineWidth = 1
    innerPath.stroke()

    let scale = size.width / 1024
    let centerX = rect.midX
    let centerY = rect.midY

    // Clipboard body
    let clipW = 500 * scale
    let clipH = 600 * scale
    let clipX = centerX - clipW / 2
    let clipY = centerY - clipH / 2 + 40 * scale
    let clipRadius = 50 * scale
    let clipRect = NSRect(x: clipX, y: clipY, width: clipW, height: clipH)
    let clipPath = NSBezierPath(roundedRect: clipRect, xRadius: clipRadius, yRadius: clipRadius)

    NSColor(white: 1, alpha: 0.92).setFill()
    clipPath.fill()

    // Clip top ring
    let ringW = 120 * scale
    let ringH = 80 * scale
    let ringX = centerX - ringW / 2
    let ringY = clipY + clipH - 20 * scale
    let ringRect = NSRect(x: ringX, y: ringY, width: ringW, height: ringH)
    let ringPath = NSBezierPath(roundedRect: ringRect, xRadius: ringH / 2, yRadius: ringH / 2)
    NSColor(white: 1, alpha: 0.92).setFill()
    ringPath.fill()

    // Ring hole
    let holeW = 60 * scale
    let holeH = 40 * scale
    let holeX = centerX - holeW / 2
    let holeY = ringY + ringH / 2 - holeH / 2
    let holeRect = NSRect(x: holeX, y: holeY, width: holeW, height: holeH)
    let holePath = NSBezierPath(roundedRect: holeRect, xRadius: holeH / 2, yRadius: holeH / 2)
    NSColor(red: 0.15, green: 0.35, blue: 0.75, alpha: 1).setFill()
    holePath.fill()

    // Scorpion SVG-inspired silhouette inside clipboard
    let bodyColor = NSColor(red: 0.15, green: 0.35, blue: 0.75, alpha: 0.85)

    // Scorpion body (oval)
    let bodyW = 220 * scale
    let bodyH = 120 * scale
    let bodyX = centerX - bodyW / 2
    let bodyY = centerY - bodyH / 2 - 20 * scale
    let bodyRect = NSRect(x: bodyX, y: bodyY, width: bodyW, height: bodyH)
    let bodyPath = NSBezierPath(ovalIn: bodyRect)
    bodyColor.setFill()
    bodyPath.fill()

    // Scorpion tail (curved line segments)
    let tail = NSBezierPath()
    tail.lineWidth = 28 * scale
    tail.lineCapStyle = .round
    tail.lineJoinStyle = .round
    var tailX = centerX
    var tailY = bodyY - 20 * scale
    tail.move(to: NSPoint(x: tailX, y: tailY))
    // Curved tail going down-left then curling up
    tail.curve(to: NSPoint(x: tailX - 120 * scale, y: tailY - 100 * scale),
               controlPoint1: NSPoint(x: tailX - 30 * scale, y: tailY - 40 * scale),
               controlPoint2: NSPoint(x: tailX - 60 * scale, y: tailY - 100 * scale))
    tail.curve(to: NSPoint(x: tailX - 80 * scale, y: tailY - 160 * scale),
               controlPoint1: NSPoint(x: tailX - 160 * scale, y: tailY - 100 * scale),
               controlPoint2: NSPoint(x: tailX - 130 * scale, y: tailY - 160 * scale))
    // Stinger
    tail.curve(to: NSPoint(x: tailX - 100 * scale, y: tailY - 180 * scale),
               controlPoint1: NSPoint(x: tailX - 70 * scale, y: tailY - 150 * scale),
               controlPoint2: NSPoint(x: tailX - 100 * scale, y: tailY - 170 * scale))
    bodyColor.setStroke()
    tail.stroke()

    // Stinger dot
    let stingerPath = NSBezierPath(ovalIn: NSRect(x: tailX - 105 * scale, y: tailY - 190 * scale, width: 22 * scale, height: 22 * scale))
    NSColor(red: 0.85, green: 0.2, blue: 0.2, alpha: 1).setFill()
    stingerPath.fill()

    // Left pincer
    let leftPincer = NSBezierPath()
    leftPincer.lineWidth = 22 * scale
    leftPincer.lineCapStyle = .round
    leftPincer.move(to: NSPoint(x: bodyX + 10 * scale, y: bodyY + bodyH / 2 + 10 * scale))
    leftPincer.curve(to: NSPoint(x: bodyX - 70 * scale, y: bodyY + bodyH / 2 + 80 * scale),
                     controlPoint1: NSPoint(x: bodyX - 20 * scale, y: bodyY + bodyH / 2 + 30 * scale),
                     controlPoint2: NSPoint(x: bodyX - 40 * scale, y: bodyY + bodyH / 2 + 50 * scale))
    bodyColor.setStroke()
    leftPincer.stroke()

    // Left claw top
    let leftClawTop = NSBezierPath()
    leftClawTop.lineWidth = 16 * scale
    leftClawTop.lineCapStyle = .round
    leftClawTop.move(to: NSPoint(x: bodyX - 70 * scale, y: bodyY + bodyH / 2 + 80 * scale))
    leftClawTop.line(to: NSPoint(x: bodyX - 100 * scale, y: bodyY + bodyH / 2 + 100 * scale))
    bodyColor.setStroke()
    leftClawTop.stroke()

    // Left claw bottom
    let leftClawBottom = NSBezierPath()
    leftClawBottom.lineWidth = 16 * scale
    leftClawBottom.lineCapStyle = .round
    leftClawBottom.move(to: NSPoint(x: bodyX - 70 * scale, y: bodyY + bodyH / 2 + 80 * scale))
    leftClawBottom.line(to: NSPoint(x: bodyX - 90 * scale, y: bodyY + bodyH / 2 + 110 * scale))
    bodyColor.setStroke()
    leftClawBottom.stroke()

    // Right pincer
    let rightPincer = NSBezierPath()
    rightPincer.lineWidth = 22 * scale
    rightPincer.lineCapStyle = .round
    rightPincer.move(to: NSPoint(x: bodyX + bodyW - 10 * scale, y: bodyY + bodyH / 2 + 10 * scale))
    rightPincer.curve(to: NSPoint(x: bodyX + bodyW + 70 * scale, y: bodyY + bodyH / 2 + 80 * scale),
                      controlPoint1: NSPoint(x: bodyX + bodyW + 20 * scale, y: bodyY + bodyH / 2 + 30 * scale),
                      controlPoint2: NSPoint(x: bodyX + bodyW + 40 * scale, y: bodyY + bodyH / 2 + 50 * scale))
    bodyColor.setStroke()
    rightPincer.stroke()

    // Right claw top
    let rightClawTop = NSBezierPath()
    rightClawTop.lineWidth = 16 * scale
    rightClawTop.lineCapStyle = .round
    rightClawTop.move(to: NSPoint(x: bodyX + bodyW + 70 * scale, y: bodyY + bodyH / 2 + 80 * scale))
    rightClawTop.line(to: NSPoint(x: bodyX + bodyW + 100 * scale, y: bodyY + bodyH / 2 + 100 * scale))
    bodyColor.setStroke()
    rightClawTop.stroke()

    // Right claw bottom
    let rightClawBottom = NSBezierPath()
    rightClawBottom.lineWidth = 16 * scale
    rightClawBottom.lineCapStyle = .round
    rightClawBottom.move(to: NSPoint(x: bodyX + bodyW + 70 * scale, y: bodyY + bodyH / 2 + 80 * scale))
    rightClawBottom.line(to: NSPoint(x: bodyX + bodyW + 90 * scale, y: bodyY + bodyH / 2 + 110 * scale))
    bodyColor.setStroke()
    rightClawBottom.stroke()

    // Legs (small lines on each side)
    let legSpecs: [(CGFloat, CGFloat)] = [
        (0.25, 0.4), (0.4, 0.3), (0.6, 0.3), (0.75, 0.4)
    ]
    for (t, offset) in legSpecs {
        let legY = bodyY + bodyH * t

        // Left leg
        let leftLeg = NSBezierPath()
        leftLeg.lineWidth = 12 * scale
        leftLeg.lineCapStyle = .round
        leftLeg.move(to: NSPoint(x: bodyX + 5 * scale, y: legY))
        leftLeg.line(to: NSPoint(x: bodyX - 40 * scale, y: legY - 30 * scale * offset))
        bodyColor.setStroke()
        leftLeg.stroke()

        // Right leg
        let rightLeg = NSBezierPath()
        rightLeg.lineWidth = 12 * scale
        rightLeg.lineCapStyle = .round
        rightLeg.move(to: NSPoint(x: bodyX + bodyW - 5 * scale, y: legY))
        rightLeg.line(to: NSPoint(x: bodyX + bodyW + 40 * scale, y: legY - 30 * scale * offset))
        bodyColor.setStroke()
        rightLeg.stroke()
    }

    // Eyes (two small dots)
    let eyeR = 10 * scale
    let eyeY = bodyY + bodyH * 0.35
    let eyeSpacing = 40 * scale
    let eyeColor = NSColor.white

    let leftEye = NSBezierPath(ovalIn: NSRect(x: centerX - eyeSpacing - eyeR, y: eyeY - eyeR, width: eyeR * 2, height: eyeR * 2))
    eyeColor.setFill()
    leftEye.fill()

    let rightEye = NSBezierPath(ovalIn: NSRect(x: centerX + eyeSpacing - eyeR, y: eyeY - eyeR, width: eyeR * 2, height: eyeR * 2))
    eyeColor.setFill()
    rightEye.fill()

    image.unlockFocus()
    return image
}

// Generate all sizes
for size in sizes {
    for scale in [1, 2] {
        let actualSize = size * scale
        let filename = scale == 1 ? "icon_\(size)x\(size).png" : "icon_\(size)x\(size)@2x.png"
        let outputURL = outputDir.appendingPathComponent(filename)

        let img = drawIcon(size: NSSize(width: actualSize, height: actualSize))
        guard let cgImage = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("Failed to generate image for size \(actualSize)")
            continue
        }
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("Failed to encode PNG for size \(actualSize)")
            continue
        }
        try pngData.write(to: outputURL)
        print("Generated \(filename) (\(actualSize)x\(actualSize))")
    }
}
