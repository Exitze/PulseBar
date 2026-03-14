import SwiftUI

struct SmartStatusView: View {
    let status: SmartStatus
    @State private var pulse = false

    private var color: Color {
        switch status.level {
        case .good:     return .accentGreen
        case .warning:  return .accentOrange
        case .critical: return .accentRed
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: status.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
                .frame(width: 18)

            Text(status.message)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.18), lineWidth: 1)
        )
        .scaleEffect(pulse ? 1.02 : 1.0)
        .animation(
            status.level == .critical
                ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                : .default,
            value: pulse
        )
        .onAppear {
            if status.level == .critical { pulse = true }
        }
        .onChange(of: status.level == .critical) { isCritical in
            pulse = isCritical
        }
    }
}
