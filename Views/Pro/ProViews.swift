import SwiftUI

// MARK: - Feature 9: Theme Editor View
struct ThemeEditorView: View {
    @StateObject private var themeSvc = ThemeService.shared
    @State private var showCustomizer = false
    @State private var customTheme:   PulseBarTheme = .defaultDark

    let builtIn: [PulseBarTheme] = [.defaultDark, .neon, .monochrome]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Themes").font(.title2.bold())

                // Built-in grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(builtIn) { theme in
                        ThemeCard(theme: theme, isSelected: themeSvc.currentTheme.name == theme.name) {
                            themeSvc.apply(theme)
                        }
                    }
                }

                Button("Create Custom Theme") { customTheme = themeSvc.currentTheme; showCustomizer = true }
                    .buttonStyle(.bordered)
            }
            .padding(20)
        }
        .sheet(isPresented: $showCustomizer) {
            ThemeCustomizerSheet(theme: $customTheme) { saved in
                themeSvc.save(custom: saved)
            }
        }
    }
}

struct ThemeCard: View {
    var theme:      PulseBarTheme
    var isSelected: Bool
    var onTap:      () -> Void
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Color swatches
                HStack(spacing: 4) {
                    ForEach([theme.cpu, theme.ram, theme.gpu, theme.network], id: \.description) { c in
                        Circle().fill(c).frame(width: 10, height: 10)
                    }
                }
                Text(theme.name).font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity).padding(12)
            .background(theme.background).cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: isSelected ? 2 : 1))
        }.buttonStyle(.plain)
    }
}

struct ThemeCustomizerSheet: View {
    @Binding var theme: PulseBarTheme
    var onSave: (PulseBarTheme) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var name = "My Theme"

    var body: some View {
        VStack(spacing: 0) {
            Text("Custom Theme").font(.title3.bold()).padding()
            Form {
                Section("Name") { TextField("Theme name", text: $name) }
                Section("Metric Colors") {
                    ColorPickerRow(label: "CPU",     hex: $theme.cpuColor)
                    ColorPickerRow(label: "RAM",     hex: $theme.ramColor)
                    ColorPickerRow(label: "GPU",     hex: $theme.gpuColor)
                    ColorPickerRow(label: "Network", hex: $theme.networkColor)
                    ColorPickerRow(label: "Disk",    hex: $theme.diskColor)
                    ColorPickerRow(label: "Battery", hex: $theme.batteryColor)
                }
            }.formStyle(.grouped)
            HStack {
                Button("Cancel") { dismiss() }.buttonStyle(.borderless)
                Spacer()
                Button("Save Theme") {
                    var saved = theme; saved = PulseBarTheme(
                        id: UUID(), name: name,
                        cpuColor: theme.cpuColor, ramColor: theme.ramColor, gpuColor: theme.gpuColor,
                        networkColor: theme.networkColor, diskColor: theme.diskColor, batteryColor: theme.batteryColor,
                        backgroundColor: theme.backgroundColor, cardColor: theme.cardColor, isBuiltIn: false)
                    onSave(saved); dismiss()
                }.buttonStyle(.borderedProminent)
            }.padding()
        }.frame(width: 440, height: 520)
    }
}

struct ColorPickerRow: View {
    var label: String
    @Binding var hex: String
    // FIXED: removed unused @State private var color

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            ColorPicker("", selection: Binding(
                get: { Color(hex: hex) },
                set: { c in
                    if let nsC = NSColor(c).usingColorSpace(.sRGB) {
                        hex = String(format: "#%02X%02X%02X",
                                     Int(nsC.redComponent * 255),
                                     Int(nsC.greenComponent * 255),
                                     Int(nsC.blueComponent * 255))
                    }
                }
            )).labelsHidden()
        }
    }
}

// MARK: - Feature 12: Popup Editor View
struct PopupEditorView: View {
    @AppStorage("popupCardOrder") var cardOrderRaw: String =
        "cpuTemp:1,cpuLoad:1,memory:1,battery:1,network:1,disk:1,gpu:0,processes:0"
    @State private var cards: [PopupCard] = []

    struct PopupCard: Identifiable {
        let id: String; var name: String; var icon: String
        var isVisible: Bool; var color: Color
    }

    private let allCards: [(String, String, String, Color)] = [
        ("cpuTemp","CPU Temp","thermometer",.orange),
        ("cpuLoad","CPU Load","cpu",.blue),
        ("memory","Memory","memorychip",.purple),
        ("battery","Battery","battery.75",.green),
        ("network","Network","network",.teal),
        ("disk","Disk","internaldrive",.blue),
        ("gpu","GPU","rectangle.3.group",.cyan),
        ("processes","Processes","list.bullet",.orange),
    ]

    var body: some View {
        HStack(spacing: 20) {
            // Left: draggable list
            VStack(alignment: .leading, spacing: 8) {
                Text("CARD ORDER").font(.system(size: 10, weight: .semibold)).tracking(1.2).foregroundColor(.secondary)
                List {
                    ForEach($cards) { $card in
                        HStack(spacing: 10) {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.secondary).font(.system(size: 12))
                            Image(systemName: card.icon).foregroundColor(card.color).font(.system(size: 14)).frame(width: 20)
                            Text(card.name).font(.system(size: 13))
                            Spacer()
                            Toggle("", isOn: $card.isVisible).toggleStyle(.switch).controlSize(.mini)
                                .onChange(of: card.isVisible) { _ in saveOrder() }
                        }.padding(.vertical, 4)
                    }
                    .onMove { from, to in cards.move(fromOffsets: from, toOffset: to); saveOrder() }
                }
                .listStyle(.plain)
            }.frame(width: 240)

            Divider()

            // Right: live preview
            VStack(alignment: .leading, spacing: 8) {
                Text("PREVIEW").font(.system(size: 10, weight: .semibold)).tracking(1.2).foregroundColor(.secondary)
                VStack(spacing: 4) {
                    ForEach(cards.filter(\.isVisible).prefix(6)) { card in
                        HStack(spacing: 8) {
                            Image(systemName: card.icon).foregroundColor(card.color).font(.system(size: 11))
                            Text(card.name).font(.system(size: 11)).foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("--").font(.system(size: 11, weight: .semibold)).foregroundColor(card.color)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(card.color.opacity(0.06)).cornerRadius(6)
                    }
                }
                .padding(10)
                .background(Color(hex: "#111113"))
                .cornerRadius(12).frame(width: 220)
            }
        }
        .padding(20)
        .onAppear { loadCards() }
    }

    private func loadCards() {
        let pairs = cardOrderRaw.split(separator: ",").map { s -> (String, Bool) in
            let p = s.split(separator: ":"); return (String(p[0]), (p.count > 1 && p[1] == "1"))
        }
        var result: [PopupCard] = []
        for (key, vis) in pairs {
            if let def = allCards.first(where: { $0.0 == key }) {
                result.append(PopupCard(id: def.0, name: def.1, icon: def.2, isVisible: vis, color: def.3))
            }
        }
        // Append any cards not in saved order
        for def in allCards where !result.contains(where: { $0.id == def.0 }) {
            result.append(PopupCard(id: def.0, name: def.1, icon: def.2, isVisible: false, color: def.3))
        }
        cards = result
    }

    func saveOrder() {
        cardOrderRaw = cards.map { "\($0.id):\($0.isVisible ? 1 : 0)" }.joined(separator: ",")
    }
}

// MARK: - Feature 10: Secondary Bar View
struct SecondaryBarView: View {
    var metrics: [String]
    @EnvironmentObject var monitor: MonitorService

    var body: some View {
        HStack(spacing: 12) {
            ForEach(metrics, id: \.self) { metric in
                MetricPill(metric: metric).environmentObject(monitor)
            }
        }
        .padding(.horizontal, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(6)
    }
}

struct MetricPill: View {
    var metric: String
    @EnvironmentObject var monitor: MonitorService

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 9))
            Text(value).font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(.white)
    }

    var icon: String {
        switch metric {
        case "cpu": return "cpu"; case "ram": return "memorychip"; case "gpu": return "rectangle.3.group"
        case "network": return "network"; case "disk": return "internaldrive"; case "battery": return "battery.75"
        default: return "circle"
        }
    }
    var value: String {
        switch metric {
        case "cpu": return "\(Int(monitor.cpuData.temperature))°"
        case "ram": return String(format: "%.1fG", monitor.ramData.usedGB)
        case "gpu": return "\(Int(monitor.gpuData.usagePercentage))%"
        case "network": return monitor.networkData.uploadBytesPerSec.shortNetworkFormatted()
        case "battery": return "\(Int(monitor.batteryData.percentage))%"
        default: return "--"
        }
    }
}

// MARK: - Pro Locked Gate View
struct ProLockedView: View {
    var featureName: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill").font(.system(size: 32)).foregroundColor(.accentOrange)
            Text(featureName).font(.title3.bold())
            Text("Available in PulseBar Pro").foregroundColor(.secondary)
            Button("Upgrade to Pro — $2.99") {
                NSApp.sendAction(#selector(AppDelegate.openSettingsProTab), to: nil, from: nil)
            }.buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
