import SwiftUI

// MARK: - Feature 2: Odometer Text Animation
struct OdometerText: View {
    var value: String
    var font: Font = .system(size: 40, weight: .bold, design: .rounded)
    var color: Color = .white

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(value.enumerated()), id: \.offset) { _, ch in
                if ch == "." || ch == "°" || ch == "%" {
                    Text(String(ch))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(color.opacity(0.5))
                } else {
                    SingleDigitOdometer(digit: ch, color: color, font: font)
                }
            }
        }
    }
}

struct SingleDigitOdometer: View {
    var digit: Character
    var color: Color
    var font: Font
    @State private var offset: CGFloat = 0

    var body: some View {
        Text(String(digit))
            .font(font)
            .foregroundColor(color)
            .offset(y: offset)
            .clipped()
            .onChange(of: digit) { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    offset = -8
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    offset = 8
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        offset = 0
                    }
                }
            }
    }
}
