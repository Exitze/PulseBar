import SwiftUI

// MARK: - Feature 1: Gradient Arc Indicator
struct ArcIndicatorView: View {
    var value: Double        // 0.0 to 1.0
    var color: Color
    var size: CGFloat = 52
    var lineWidth: CGFloat = 5
    var label: String = ""

    var body: some View {
        ZStack {
            // Track
            Circle()
                .trim(from: 0.1, to: 0.9)
                .stroke(color.opacity(0.12),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(90))

            // Fill arc with angular gradient
            Circle()
                .trim(from: 0.1, to: 0.1 + 0.8 * min(value, 1.0))
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.6), color],
                        center: .center,
                        startAngle: .degrees(90),
                        endAngle:   .degrees(90 + 288)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(90))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: value)

            // Center label
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
        }
        .frame(width: size, height: size)
    }
}
