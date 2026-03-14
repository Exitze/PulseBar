import SwiftUI

struct CoreHeatmapView: View {
    @EnvironmentObject var monitor: MonitorService
    let columns = [GridItem(.adaptive(minimum: 28), spacing: 4)]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CORES")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .foregroundColor(.white.opacity(0.3))

            if monitor.coreUsages.isEmpty {
                Text("Loading…")
                    .font(.system(size: 11))
                    .foregroundColor(Color.textTertiary)
            } else {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(Array(monitor.coreUsages.enumerated()), id: \.offset) { i, load in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(coreColor(load))
                            .frame(height: 28)
                            .overlay(
                                Text("\(Int(load * 100))")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                            )
                            .animation(.spring(response: 0.4), value: load)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardRadius)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    func coreColor(_ load: Double) -> Color {
        switch load {
        case 0..<0.3:   return Color(hex8: "#1A3A2A")
        case 0.3..<0.6: return Color(hex8: "#3A2E0A")
        case 0.6..<0.8: return Color(hex8: "#3A1A0A")
        default:        return Color(hex8: "#3A0A0A")
        }
    }
}
