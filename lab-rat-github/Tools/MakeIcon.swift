import AppKit

let output = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)

func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, alpha: 1)
}
func paintIcon(_ pixels: Int, at path: String) throws {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let graphics = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = graphics
    graphics.cgContext.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
    func ellipse(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ hex: UInt32) { color(hex).setFill(); NSBezierPath(ovalIn: NSRect(x: x, y: y, width: w, height: h)).fill() }
    color(0x202923).setFill(); NSBezierPath(roundedRect: NSRect(x: 30, y: 30, width: 964, height: 964), xRadius: 215, yRadius: 215).fill()
    color(0xD4ED88).setStroke(); let ring = NSBezierPath(ovalIn: NSRect(x: 139, y: 139, width: 746, height: 746)); ring.lineWidth = 14; ring.stroke()
    let tail = NSBezierPath(); tail.move(to: NSPoint(x: 630, y: 286)); tail.curve(to: NSPoint(x: 811, y: 390), controlPoint1: NSPoint(x: 853, y: 231), controlPoint2: NSPoint(x: 852, y: 321)); tail.lineWidth = 26; tail.lineCapStyle = .round; color(0xD5A89F).setStroke(); tail.stroke()
    ellipse(323, 238, 378, 349, 0xE4E7DB)
    ellipse(267, 589, 216, 228, 0xB6C1B3); ellipse(563, 589, 216, 228, 0xB6C1B3)
    ellipse(299, 627, 152, 152, 0xE8B9AB); ellipse(595, 627, 152, 152, 0xE8B9AB)
    ellipse(307, 430, 426, 364, 0xB6C1B3)
    ellipse(410, 627, 37, 47, 0x171A19); ellipse(601, 627, 37, 47, 0x171A19)
    ellipse(491, 527, 62, 41, 0xE8B9AB)
    let whiskers = NSBezierPath(); whiskers.lineWidth = 8; whiskers.lineCapStyle = .round
    for y: CGFloat in [528, 566] { whiskers.move(to: NSPoint(x: 438, y: y)); whiskers.line(to: NSPoint(x: 283, y: y + 28)); whiskers.move(to: NSPoint(x: 595, y: y)); whiskers.line(to: NSPoint(x: 750, y: y + 28)) }; color(0x38463B).setStroke(); whiskers.stroke()
    let collar = NSBezierPath(); collar.move(to: NSPoint(x: 409, y: 448)); collar.line(to: NSPoint(x: 514, y: 369)); collar.line(to: NSPoint(x: 620, y: 448)); collar.lineWidth = 10; color(0x939F91).setStroke(); collar.stroke()
    ellipse(505, 337, 20, 20, 0x939F91); ellipse(505, 281, 20, 20, 0x939F91)
    color(0xD4ED88).setFill(); NSBezierPath(roundedRect: NSRect(x: 661, y: 264, width: 68, height: 146), xRadius: 23, yRadius: 23).fill()
    color(0x171A19).setFill(); NSBezierPath(roundedRect: NSRect(x: 654, y: 405, width: 83, height: 28), xRadius: 6, yRadius: 6).fill()
    NSGraphicsContext.restoreGraphicsState()
    try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}
for (name, size) in [("icon_16x16.png", 16), ("icon_16x16@2x.png", 32), ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64), ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256), ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512), ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)] { try paintIcon(size, at: output + "/" + name) }

// PNG-backed ICNS elements avoid dependencies on the system icon conversion service.
func bigEndian(_ number: Int) -> Data {
    var value = UInt32(number).bigEndian
    return withUnsafeBytes(of: &value) { Data($0) }
}
var elements = Data()
for (type, file) in [("icp4", "icon_16x16.png"), ("icp5", "icon_32x32.png"), ("icp6", "icon_32x32@2x.png"), ("ic07", "icon_128x128.png"), ("ic08", "icon_256x256.png"), ("ic09", "icon_512x512.png"), ("ic10", "icon_512x512@2x.png"), ("ic11", "icon_16x16@2x.png"), ("ic12", "icon_32x32@2x.png"), ("ic13", "icon_128x128@2x.png"), ("ic14", "icon_256x256@2x.png")] {
    let png = try Data(contentsOf: URL(fileURLWithPath: output + "/" + file))
    elements.append(Data(type.utf8)); elements.append(bigEndian(png.count + 8)); elements.append(png)
}
var icon = Data("icns".utf8); icon.append(bigEndian(elements.count + 8)); icon.append(elements)
try icon.write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
