import SwiftUI

struct GPUCard: View {
    let gpu: GPUData

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "display.2")
                        .foregroundStyle(Color.accentBlue)
                        .font(.system(size: 14))
                    Text("GPU Monitor")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                    Spacer()
                }

                HStack(spacing: 16) {
                    // GPU Load
                    VStack(spacing: 8) {
                        ZStack {
                            ArcRing(progress: gpu.usagePercentage / 100.0, color: .accentBlue)
                                .frame(width: 56, height: 56)
                            Text(String(format: "%.0f%%", gpu.usagePercentage))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        Text("GPU Load")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        // GPU Temp
                        HStack(spacing: 6) {
                            Image(systemName: "thermometer.medium")
                                .foregroundStyle(tempColor(gpu.temperature))
                                .font(.system(size: 11))
                            Text(String(format: "%.0f°C", gpu.temperature))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(tempColor(gpu.temperature))
                            Text("GPU Temp")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.secondary)
                        }

                        // VRAM
                        HStack(spacing: 6) {
                            Image(systemName: "memorychip")
                                .foregroundStyle(Color.accentPurple)
                                .font(.system(size: 11))
                            Text(String(format: "%.1f / %.0f GB VRAM", gpu.vramUsedGB, gpu.vramTotalGB))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                        // VRAM bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.accentPurple)
                                    .frame(width: gpu.vramTotalGB > 0
                                           ? geo.size.width * min(gpu.vramUsedGB / gpu.vramTotalGB, 1.0)
                                           : 0,
                                           height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !gpu.activeProcesses.isEmpty {
                    Rectangle().fill(Color.white.opacity(0.08)).frame(height:1)
                    Text("Active Metal Processes")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.secondary)
                    ForEach(gpu.activeProcesses.prefix(3), id: \.self) { proc in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.accentBlue)
                                .frame(width: 5, height: 5)
                            Text(proc)
                                .font(.system(size: 10))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
        }
    }
}
