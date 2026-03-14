import SwiftUI
import AppKit

// ═══════════════════════════════════════════════════
// MARK: - Color Palette
// ═══════════════════════════════════════════════════
extension Color {
    // Backgrounds
    static let appBg        = Color(hex8: "#0A0A0A")
    static let cardBg       = Color(hex8: "#111113")
    static let cardBorder   = Color.white.opacity(0.06)
    static let cardBorderHi = Color.white.opacity(0.12)
    static let sep          = Color.white.opacity(0.05)

    // Accents
    static let accentBlue   = Color(hex8: "#0A84FF")
    static let accentGreen  = Color(hex8: "#32D74B")
    static let accentOrange = Color(hex8: "#FF9F0A")
    static let accentRed    = Color(hex8: "#FF453A")
    static let accentPurple = Color(hex8: "#BF5AF2")
    static let accentTeal   = Color(hex8: "#5AC8FA")
    static let accentYellow = Color(hex8: "#FFD60A")

    // Text
    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.45)
    static let textTertiary  = Color.white.opacity(0.20)

    // Hex8 init (preferred — takes #RRGGBB)
    init(hex8 string: String) {
        // FIXED: changed var → let since hex is never mutated
        let hex = string.trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >>  8) & 0xFF) / 255,
            blue:  Double( rgb        & 0xFF) / 255
        )
    }

    // Hex init (Feature 3 — same behavior, alternate label)
    init(hex string: String) { self.init(hex8: string) }
}

// ═══════════════════════════════════════════════════
// MARK: - Feature 3: Smart Color Threshold Functions
// ═══════════════════════════════════════════════════
func cpuTempColor(_ temp: Double) -> Color {
    switch temp {
    case ..<50:   return .accentGreen
    case 50..<70: return .accentOrange
    default:      return .accentRed
    }
}

func cpuLoadColor(_ load: Double) -> Color {
    switch load {
    case ..<40:   return .accentBlue
    case 40..<75: return .accentOrange
    default:      return .accentRed
    }
}

func batteryColorFor(_ level: Double, charging: Bool) -> Color {
    if charging { return .accentGreen }
    switch Int(level) {
    case 20...: return .accentGreen
    case 10..<20: return .accentOrange
    default:      return .accentRed
    }
}

// ═══════════════════════════════════════════════════
// MARK: - Typography
// ═══════════════════════════════════════════════════
extension Font {
    static let bigNumber     = Font.system(size: 40, weight: .bold, design: .rounded)
    static let mediumNumber  = Font.system(size: 28, weight: .bold, design: .rounded)
    static let metricLabel   = Font.system(size: 10, weight: .semibold)
    static let metricSub     = Font.system(size: 11, weight: .regular)
    static let cardTitle     = Font.system(size: 13, weight: .semibold)
    static let bodyText      = Font.system(size: 13, weight: .regular)
    static let tinyText      = Font.system(size: 10, weight: .regular)
}

// ═══════════════════════════════════════════════════
// MARK: - Geometry constants
// ═══════════════════════════════════════════════════
enum DS {
    static let popupWidth:   CGFloat = 300
    static let outerRadius:  CGFloat = 20
    static let cardRadius:   CGFloat = 14
    static let innerRadius:  CGFloat = 8
    static let cardPadding:  CGFloat = 14
    static let gridGap:      CGFloat = 8
    static let outerPadding: CGFloat = 14
}

// ═══════════════════════════════════════════════════
// MARK: - MetricCard container with hover effect
// ═══════════════════════════════════════════════════
struct MetricCard<Content: View>: View {
    let accent: Color
    let bgOpacity: Double
    let borderOpacity: Double
    @ViewBuilder var content: () -> Content
    @State private var hovered = false

    init(accent: Color,
         bgOpacity: Double = 0.08,
         borderOpacity: Double = 0.15,
         @ViewBuilder content: @escaping () -> Content) {
        self.accent        = accent
        self.bgOpacity     = bgOpacity
        self.borderOpacity = borderOpacity
        self.content       = content
    }

    var body: some View {
        content()
            .padding(DS.cardPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(accent.opacity(hovered ? bgOpacity * 1.3 : bgOpacity))
            .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DS.cardRadius)
                    .stroke(accent.opacity(hovered ? borderOpacity * 1.8 : borderOpacity), lineWidth: 1)
            )
            .scaleEffect(hovered ? 1.012 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: hovered)
            .onHover { hovered = $0 }
    }
}

// MARK: - backward-compat Card alias
struct Card<Content: View>: View {
    @ViewBuilder var content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    var body: some View {
        content()
            .padding(DS.cardPadding)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(Color.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(Color.cardBorder, lineWidth: 1))
    }
}

// ═══════════════════════════════════════════════════
// MARK: - ThinProgressBar
// ═══════════════════════════════════════════════════
struct ThinProgressBar: View {
    let value: Double   // 0-100
    let color: Color
    var height: CGFloat = 2

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.08)).frame(height: height)
                Capsule().fill(color)
                    .frame(width: max(0, geo.size.width * CGFloat(min(value, 100) / 100)),
                           height: height)
                    .animation(.easeInOut(duration: 0.3), value: value)
            }
        }
        .frame(height: height)
    }
}

// ═══════════════════════════════════════════════════
// MARK: - Mini Arc Ring (Disk card — backward compat)
// ═══════════════════════════════════════════════════
struct ArcRing: View {
    let progress: Double
    let color: Color
    var size: CGFloat = 40
    var lineWidth: CGFloat = 4

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// ═══════════════════════════════════════════════════
// MARK: - Network format helper
// ═══════════════════════════════════════════════════
extension Double {
    func networkFormatted() -> String {
        if self < 1_000         { return String(format: "%.0f B/s",   self) }
        if self < 1_000_000     { return String(format: "%.1f KB/s",  self / 1_000) }
        if self < 1_000_000_000 { return String(format: "%.1f MB/s",  self / 1_000_000) }
        return String(format: "%.1f GB/s", self / 1_000_000_000)
    }
}

// MARK: - Legacy free function (backward compat)
func tempColor(_ temp: Double) -> Color { cpuTempColor(temp) }
