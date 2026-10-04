import SwiftUI

enum LabTheme {
    static let bg = Color(hex: 0x171A19)
    static let sidebar = Color(hex: 0x111413)
    static let card = Color(hex: 0x222624)
    static let line = Color(hex: 0x353B37)
    static let lime = Color(hex: 0xD4ED88)
    static let muted = Color(hex: 0x9BA69F)
    static let white = Color(hex: 0xF3F4EE)
    static let amber = Color(hex: 0xEAB77A)
}

extension Color {
    init(hex: UInt32) { self.init(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1) }
}

struct LabButtonStyle: ButtonStyle {
    var primary = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 15).padding(.vertical, 11)
            .foregroundStyle(primary ? LabTheme.bg : LabTheme.white)
            .background(primary ? LabTheme.lime : LabTheme.line, in: RoundedRectangle(cornerRadius: 9))
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}

struct Card<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View { content.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(LabTheme.card, in: RoundedRectangle(cornerRadius: 15)).overlay(RoundedRectangle(cornerRadius: 15).stroke(LabTheme.line, lineWidth: 1)) }
}

struct Eyebrow: View {
    let text: String
    var body: some View { Text(text.uppercased()).font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2).foregroundStyle(LabTheme.muted) }
}

struct Pill: View {
    let text: String
    var color: Color = LabTheme.lime
    var body: some View { Text(text).font(.system(size: 10, weight: .semibold, design: .monospaced)).foregroundStyle(color).padding(.horizontal, 9).padding(.vertical, 5).background(color.opacity(0.1), in: Capsule()) }
}

struct RatMascot: View {
    var size: CGFloat = 100
    var body: some View {
        Canvas { ctx, dimensions in
            ctx.scaleBy(x: dimensions.width / 140, y: dimensions.height / 140)
            func ellipse(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color) {
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h)), with: .color(color))
            }
            var tail = Path(); tail.move(to: CGPoint(x: 98, y: 115)); tail.addCurve(to: CGPoint(x: 132, y: 91), control1: CGPoint(x: 135, y: 128), control2: CGPoint(x: 138, y: 104))
            ctx.stroke(tail, with: .color(Color(hex: 0xD5A89F)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            ellipse(34, 65, 72, 63, Color(hex: 0xE4E7DB))
            ellipse(23, 24, 38, 40, Color(hex: 0xB6C1B3)); ellipse(81, 24, 38, 40, Color(hex: 0xB6C1B3))
            ellipse(29, 31, 26, 26, Color(hex: 0xE8B9AB)); ellipse(87, 31, 26, 26, Color(hex: 0xE8B9AB))
            ellipse(33, 36, 76, 66, Color(hex: 0xB6C1B3))
            ellipse(50, 57, 7, 9, LabTheme.bg); ellipse(85, 57, 7, 9, LabTheme.bg)
            ellipse(66, 78, 11, 8, Color(hex: 0xE8B9AB))
            var whiskers = Path()
            for y: CGFloat in [76, 83] {
                whiskers.move(to: CGPoint(x: 56, y: y)); whiskers.addLine(to: CGPoint(x: 31, y: y - 5))
                whiskers.move(to: CGPoint(x: 86, y: y)); whiskers.addLine(to: CGPoint(x: 111, y: y - 5))
            }
            ctx.stroke(whiskers, with: .color(LabTheme.bg.opacity(0.65)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            var collar = Path(); collar.move(to: CGPoint(x: 49, y: 96)); collar.addLine(to: CGPoint(x: 70, y: 111)); collar.addLine(to: CGPoint(x: 91, y: 96))
            ctx.stroke(collar, with: .color(Color(hex: 0x939F91)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            ellipse(68, 111, 4, 4, Color(hex: 0x939F91)); ellipse(68, 121, 4, 4, Color(hex: 0x939F91))
            let vial = Path(roundedRect: CGRect(x: 95, y: 94, width: 13, height: 28), cornerRadius: 5)
            ctx.fill(vial, with: .color(LabTheme.lime)); ctx.fill(Path(CGRect(x: 94, y: 91, width: 15, height: 5)), with: .color(LabTheme.bg))
        }.frame(width: size, height: size).accessibilityLabel("A small rat in a lab coat holding a green sample tube")
    }
}

struct TimerRing: View {
    var fraction: Double
    var size: CGFloat = 154
    var body: some View {
        ZStack {
            Circle().stroke(LabTheme.line, lineWidth: 5)
            Circle().trim(from: 0, to: min(1, max(0, fraction))).stroke(LabTheme.lime, style: StrokeStyle(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(-90))
            RatMascot(size: size * 0.72)
        }.frame(width: size, height: size)
    }
}
