import SwiftUI

struct ProcessCard: View {
    let topCPU: [ProcessData]
    let topRAM: [ProcessData]
    @State private var confirmKill: ProcessData? = nil
    @State private var showConfirm = false

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .foregroundStyle(Color.accentBlue)
                        .font(.system(size: 14))
                    Text("Process Inspector")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                    Spacer()
                }

                // Top CPU
                Text("TOP CPU")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                    .padding(.top, 2)

                ForEach(topCPU) { proc in
                    ProcessRow(proc: proc, valueLabel: String(format: "%.1f%%", proc.cpuPercentage),
                               barColor: .accentBlue, barValue: proc.cpuPercentage / 100.0) {
                        confirmKill = proc
                        showConfirm = true
                    }
                }

                Rectangle().fill(Color.cardBorder).frame(height:1).padding(.vertical, 4)

                // Top RAM
                Text("TOP MEMORY")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.secondary)

                ForEach(topRAM) { proc in
                    let mb = Double(proc.ramBytes) / 1_048_576.0
                    let label = mb > 1024 ? String(format: "%.1f GB", mb / 1024) : String(format: "%.0f MB", mb)
                    ProcessRow(proc: proc, valueLabel: label,
                               barColor: .accentPurple, barValue: min(mb / 4096.0, 1.0)) {
                        confirmKill = proc
                        showConfirm = true
                    }
                }
            }
        }
        .alert("Kill Process?", isPresented: $showConfirm, presenting: confirmKill) { proc in
            Button("Kill \(proc.name)", role: .destructive) {
                kill(proc.pid, SIGKILL)
            }
            Button("Cancel", role: .cancel) {}
        } message: { proc in
            Text("This will forcibly terminate \"\(proc.name)\" (PID \(proc.pid)). Unsaved work may be lost.")
        }
    }
}

struct ProcessRow: View {
    let proc: ProcessData
    let valueLabel: String
    let barColor: Color
    let barValue: Double
    let onKill: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "app.fill")
                .foregroundStyle(barColor.opacity(0.7))
                .font(.system(size: 12))
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(proc.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor)
                        .frame(width: geo.size.width * barValue, height: 3)
                        .background(
                            RoundedRectangle(cornerRadius: 2).fill(Color.cardBorder)
                        )
                }
                .frame(height: 3)
            }

            Spacer()
            Text(valueLabel)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(barColor)

            Button { onKill() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.accentRed.opacity(0.6))
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
        }
    }
}
