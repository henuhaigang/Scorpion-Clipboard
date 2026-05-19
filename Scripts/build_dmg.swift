import AppKit
import Foundation

let fm = FileManager.default

let projectDir = URL(fileURLWithPath: fm.currentDirectoryPath)
let releaseDir = projectDir.appendingPathComponent(".build/release")
let appName = "ScorpionClipboard"
let appBundleName = "\(appName).app"
let volumeName = appName
let dmgName = "\(appName).dmg"
let dmgRWName = "\(appName)_rw.dmg"
let stagingDir = projectDir.appendingPathComponent(".dmg_staging")
let appBundleDir = stagingDir.appendingPathComponent(appBundleName)

let iconSetDir = projectDir.appendingPathComponent("AppIcon.iconset")
let icnsPath = projectDir.appendingPathComponent("Resources/AppIcon.icns")
let bgDir = projectDir.appendingPathComponent(".dmg_bg")
let bgPath = bgDir.appendingPathComponent("background.png")

let ws = NSWorkspace.shared

// MARK: - Generate app icon
print("=== Generating App Icon ===")
try? fm.removeItem(at: iconSetDir)
try fm.createDirectory(at: iconSetDir, withIntermediateDirectories: true)

let sizes = [16, 32, 64, 128, 256, 512, 1024]

func drawIcon(size: NSSize) -> NSImage {
    let image = NSImage(size: size)
    image.lockFocus()
    let rect = NSRect(origin: .zero, size: size)
    let cornerRadius = size.width * 0.22
    let bgPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    bgPath.addClip()

    let gradient = NSGradient(starting: NSColor(red: 0.12, green: 0.30, blue: 0.72, alpha: 1),
                              ending: NSColor(red: 0.42, green: 0.18, blue: 0.62, alpha: 1))
    gradient?.draw(in: rect, angle: -45)

    let s = size.width / 1024
    let cx = rect.midX
    let cy = rect.midY

    let clipRect = NSRect(x: cx - 250 * s, y: cy - 260 * s, width: 500 * s, height: 580 * s)
    NSBezierPath(roundedRect: clipRect, xRadius: 50 * s, yRadius: 50 * s).fill()
    NSColor(white: 1, alpha: 0.92).setFill()
    NSBezierPath(roundedRect: clipRect, xRadius: 50 * s, yRadius: 50 * s).fill()

    let ringRect = NSRect(x: cx - 55 * s, y: clipRect.maxY - 20 * s, width: 110 * s, height: 75 * s)
    NSBezierPath(roundedRect: ringRect, xRadius: 37 * s, yRadius: 37 * s).fill()

    let holeRect = NSRect(x: cx - 25 * s, y: ringRect.midY - 15 * s, width: 50 * s, height: 30 * s)
    let holePath = NSBezierPath(roundedRect: holeRect, xRadius: 15 * s, yRadius: 15 * s)
    NSColor(red: 0.12, green: 0.30, blue: 0.72, alpha: 1).setFill()
    holePath.fill()

    let scColor = NSColor(red: 0.12, green: 0.30, blue: 0.72, alpha: 0.85)
    let bodyRect = NSRect(x: cx - 100 * s, y: cy - 60 * s, width: 200 * s, height: 110 * s)
    scColor.setFill()
    NSBezierPath(ovalIn: bodyRect).fill()

    let tailPath = NSBezierPath()
    tailPath.lineWidth = 26 * s; tailPath.lineCapStyle = .round; tailPath.lineJoinStyle = .round
    let tx = cx; let ty = bodyRect.minY - 15 * s
    tailPath.move(to: NSPoint(x: tx, y: ty))
    tailPath.curve(to: NSPoint(x: tx - 130 * s, y: ty - 120 * s),
                   controlPoint1: NSPoint(x: tx - 40 * s, y: ty - 50 * s),
                   controlPoint2: NSPoint(x: tx - 70 * s, y: ty - 100 * s))
    tailPath.curve(to: NSPoint(x: tx - 110 * s, y: ty - 170 * s),
                   controlPoint1: NSPoint(x: tx - 170 * s, y: ty - 130 * s),
                   controlPoint2: NSPoint(x: tx - 150 * s, y: ty - 170 * s))
    scColor.setStroke()
    tailPath.stroke()

    NSColor(red: 0.85, green: 0.20, blue: 0.20, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: tx - 120 * s, y: ty - 185 * s, width: 25 * s, height: 25 * s)).fill()

    func makePincer(x: CGFloat, y: CGFloat, dir: CGFloat) {
        let p = NSBezierPath(); p.lineWidth = 22 * s; p.lineCapStyle = .round
        p.move(to: NSPoint(x: x + dir * 15 * s, y: y + 15 * s))
        p.curve(to: NSPoint(x: x + dir * 80 * s, y: y + 100 * s),
                controlPoint1: NSPoint(x: x + dir * 20 * s, y: y + 40 * s),
                controlPoint2: NSPoint(x: x + dir * 50 * s, y: y + 60 * s))
        scColor.setStroke(); p.stroke()
        for dx in [CGFloat(115), CGFloat(105)] {
            let c = NSBezierPath(); c.lineWidth = 16 * s; c.lineCapStyle = .round
            c.move(to: NSPoint(x: x + dir * 80 * s, y: y + 100 * s))
            c.line(to: NSPoint(x: x + dir * dx * s, y: y + 100 * s + (dx == 115 ? 25 : 40) * s))
            scColor.setStroke(); c.stroke()
        }
    }
    makePincer(x: bodyRect.minX, y: bodyRect.midY, dir: -1)
    makePincer(x: bodyRect.maxX, y: bodyRect.midY, dir: 1)

    for (i, off): (Int, CGFloat) in [(0, 0.3), (1, 0.25), (2, 0.25), (3, 0.3)] {
        let ly = bodyRect.minY + bodyRect.height * CGFloat(i + 1) / 5
        for dir in [CGFloat(-1), CGFloat(1)] {
            let l = NSBezierPath()
            l.lineWidth = 12 * s; l.lineCapStyle = .round
            let mx = dir > 0 ? bodyRect.maxX : bodyRect.minX
            l.move(to: NSPoint(x: mx - dir * 5 * s, y: ly))
            l.line(to: NSPoint(x: mx + dir * 45 * s, y: ly - 35 * s * off))
            scColor.setStroke(); l.stroke()
        }
    }

    NSColor.white.setFill()
    let eyeR = 9 * s; let eyeY = bodyRect.minY + bodyRect.height * 0.35
    NSBezierPath(ovalIn: NSRect(x: cx - 45 * s - eyeR, y: eyeY - eyeR, width: eyeR * 2, height: eyeR * 2)).fill()
    NSBezierPath(ovalIn: NSRect(x: cx + 45 * s - eyeR, y: eyeY - eyeR, width: eyeR * 2, height: eyeR * 2)).fill()

    image.unlockFocus()
    return image
}

for size in sizes {
    for scale in [1, 2] {
        let actualSize = size * scale
        let filename = scale == 1 ? "icon_\(size)x\(size).png" : "icon_\(size)x\(size)@2x.png"
        let img = drawIcon(size: NSSize(width: actualSize, height: actualSize))
        guard let cgImage = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { continue }
        guard let pngData = NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:]) else { continue }
        try pngData.write(to: iconSetDir.appendingPathComponent(filename))
        print("  \(filename) (\(actualSize)x\(actualSize))")
    }
}

print("Converting to icns...")
try? fm.removeItem(at: icnsPath)
let iconTask = Process()
iconTask.launchPath = "/usr/bin/iconutil"
iconTask.arguments = ["-c", "icns", "--output", icnsPath.path, iconSetDir.path]
iconTask.launch()
iconTask.waitUntilExit()
try? fm.removeItem(at: iconSetDir)
guard iconTask.terminationStatus == 0 else { print("iconutil failed"); exit(1) }
print("Icon created")

// MARK: - Generate background
print("\n=== Generating Background ===")
try? fm.removeItem(at: bgDir)
try fm.createDirectory(at: bgDir, withIntermediateDirectories: true)

let bgSize = NSSize(width: 600, height: 400)
let bgImage = NSImage(size: bgSize)
bgImage.lockFocus()

let bgRect = NSRect(origin: .zero, size: bgSize)
let bgGradient = NSGradient(starting: NSColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1),
                            ending: NSColor(red: 0.88, green: 0.90, blue: 0.94, alpha: 1))
bgGradient?.draw(in: bgRect, angle: 90)

let text = "将 app 拖入 Applications 或 Install.app" as NSString
let font = NSFont.systemFont(ofSize: 16, weight: .medium)
let textAttrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 0.55)
]
let textSize = text.size(withAttributes: textAttrs)
text.draw(in: NSRect(x: (bgSize.width - textSize.width) / 2, y: 28, width: textSize.width, height: textSize.height),
          withAttributes: textAttrs)

let arrowColor = NSColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 0.18)
arrowColor.setStroke()

func drawArrow(from x1: CGFloat, to x2: CGFloat, y: CGFloat) {
    let a = NSBezierPath()
    a.lineWidth = 2.5; a.lineCapStyle = .round
    a.move(to: NSPoint(x: x1, y: y))
    a.line(to: NSPoint(x: x2, y: y))
    a.stroke()
    for d in [-CGFloat(8), CGFloat(8)] {
        let h = NSBezierPath()
        h.lineWidth = 2.5; h.lineCapStyle = .round
        h.move(to: NSPoint(x: x2, y: y))
        h.line(to: NSPoint(x: x2 - 12, y: y + d))
        h.stroke()
    }
}

drawArrow(from: 170, to: 330, y: 170)
drawArrow(from: 170, to: 530, y: 120)

let labelFont = NSFont.systemFont(ofSize: 12, weight: .semibold)
let labelColor = NSColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 0.6)
let labelAttrs: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: labelColor]

("ScorpionClipboard.app" as NSString).draw(in: NSRect(x: 120 - 56, y: 200, width: 112, height: 20), withAttributes: labelAttrs)
("Install.app" as NSString).draw(in: NSRect(x: 320 - 45, y: 200, width: 90, height: 20), withAttributes: labelAttrs)
("Applications" as NSString).draw(in: NSRect(x: 520 - 52, y: 95, width: 104, height: 20), withAttributes: labelAttrs)

bgImage.unlockFocus()

guard let bgCGImage = bgImage.cgImage(forProposedRect: nil, context: nil, hints: nil),
      let bgPNG = NSBitmapImageRep(cgImage: bgCGImage).representation(using: .png, properties: [:]) else {
    print("Failed to create background PNG"); exit(1)
}
try bgPNG.write(to: bgPath)
print("Background created")

// MARK: - Create app bundle
print("\n=== Creating App Bundle ===")
try? fm.removeItem(at: stagingDir)
try fm.createDirectory(at: stagingDir, withIntermediateDirectories: true)
try fm.createDirectory(at: appBundleDir.appendingPathComponent("Contents/MacOS"), withIntermediateDirectories: true)
try fm.createDirectory(at: appBundleDir.appendingPathComponent("Contents/Resources"), withIntermediateDirectories: true)

try fm.copyItem(at: releaseDir.appendingPathComponent(appName),
                to: appBundleDir.appendingPathComponent("Contents/MacOS/\(appName)"))
try fm.copyItem(at: projectDir.appendingPathComponent("Info.plist"),
                to: appBundleDir.appendingPathComponent("Contents/Info.plist"))
try fm.copyItem(at: icnsPath,
                to: appBundleDir.appendingPathComponent("Contents/Resources/AppIcon.icns"))
print("App bundle created")

// Copy the Install.app helper
let installAppSrc = URL(fileURLWithPath: "/tmp/Install.app")
let installAppDst = stagingDir.appendingPathComponent("Install.app")
if fm.fileExists(atPath: installAppSrc.path) {
    try fm.copyItem(at: installAppSrc, to: installAppDst)
    print("  Install.app added")
} else {
    print("  Install.app not found at /tmp/Install.app, skipping")
}

// Create Applications symlink
try fm.createSymbolicLink(at: stagingDir.appendingPathComponent("Applications"),
                          withDestinationURL: URL(fileURLWithPath: "/Applications"))
print("  Applications symlink added")

// MARK: - Create DMG
print("=== Creating DMG ===")
try? fm.removeItem(at: projectDir.appendingPathComponent(dmgRWName))
try? fm.removeItem(at: projectDir.appendingPathComponent(dmgName))

let rwPath = projectDir.appendingPathComponent(dmgRWName)
let dmgPath = projectDir.appendingPathComponent(dmgName)

let createTask = Process()
createTask.launchPath = "/usr/bin/hdiutil"
createTask.arguments = ["create", "-ov", "-srcfolder", stagingDir.path,
                        "-volname", volumeName, "-fs", "HFS+",
                        "-format", "UDRW", "-size", "120m", rwPath.path]
createTask.launch()
createTask.waitUntilExit()
guard createTask.terminationStatus == 0 else { print("Failed RW DMG"); exit(1) }

_ = try? Process.run(URL(fileURLWithPath: "/usr/bin/hdiutil"), arguments: ["detach", "/Volumes/\(volumeName)", "-force"])
sleep(1)

let attachTask = Process()
attachTask.launchPath = "/usr/bin/hdiutil"
attachTask.arguments = ["attach", rwPath.path, "-mountpoint", "/Volumes/\(volumeName)", "-nobrowse"]
attachTask.launch()
attachTask.waitUntilExit()
sleep(2)

// Copy background (after mount)
let mountURL = URL(fileURLWithPath: "/Volumes/\(volumeName)")
try? fm.createDirectory(at: mountURL.appendingPathComponent(".background"), withIntermediateDirectories: true)
try? fm.removeItem(at: mountURL.appendingPathComponent(".background/background.png"))
try fm.copyItem(at: bgPath, to: mountURL.appendingPathComponent(".background/background.png"))

// Finder layout via AppleScript (2 items only: app + Install.app)
let ascript = """
tell application "Finder"
    set retryCount to 0
    repeat while retryCount < 10
        if exists disk "\(volumeName)" then
            tell disk "\(volumeName)"
                open
                set current view of container window to icon view
                set toolbar visible of container window to false
                set statusbar visible of container window to false
                set bounds of container window to {100, 100, 750, 450}
                set viewOptions to the icon view options of container window
                set arrangement of viewOptions to not arranged
                set icon size of viewOptions to 80
                set background picture of viewOptions to file ".background:background.png"
                try
                    set position of item "\(appBundleName)" to {120, 180}
                    set position of item "Install.app" to {320, 180}
                    set position of item "Applications" to {520, 180}
                end try
                close
            end tell
            exit repeat
        end if
        delay 0.5
        set retryCount to retryCount + 1
    end repeat
end tell
"""

let asc = Process()
asc.launchPath = "/usr/bin/osascript"
asc.arguments = ["-e", ascript]
asc.launch()
asc.waitUntilExit()
sleep(1)

_ = try? Process.run(URL(fileURLWithPath: "/usr/bin/hdiutil"), arguments: ["detach", "/Volumes/\(volumeName)", "-force"])
sleep(2)

let convertTask = Process()
convertTask.launchPath = "/usr/bin/hdiutil"
convertTask.arguments = ["convert", rwPath.path, "-format", "UDZO",
                         "-imagekey", "zlib-level=9", "-o", dmgPath.path]
convertTask.launch()
convertTask.waitUntilExit()

try? fm.removeItem(at: rwPath)
try? fm.removeItem(at: stagingDir)
try? fm.removeItem(at: bgDir)

if convertTask.terminationStatus == 0 {
    let size = (try? fm.attributesOfItem(atPath: dmgPath.path)[.size] as? Int64) ?? 0
    print("\n✅ DMG: \(dmgPath.path) (\(size / 1024) KB)")
} else {
    print("❌ DMG failed")
}
