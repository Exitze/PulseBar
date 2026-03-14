import SwiftUI
import AppKit

// MARK: - Module enum for sidebar
enum SettingsModule: String, CaseIterable, Identifiable {
    case cpu, ram, gpu, network, disk, battery
    case history, benchmark, autokill, themes, layout, alerts, about
    var id: String { rawValue }
    var title: String {
        switch self {
        case .cpu: return "CPU"; case .ram: return "RAM"; case .gpu: return "GPU"
        case .network: return "Network"; case .disk: return "Disk"; case .battery: return "Battery"
        case .history: return "History"; case .benchmark: return "Benchmark"
        case .autokill: return "Auto-Kill"; case .themes: return "Themes"
        case .layout: return "Layout"; case .alerts: return "Alerts"; case .about: return "About"
        }
    }
    var sfSymbol: String {
        switch self {
        case .cpu: return "cpu"; case .ram: return "memorychip"; case .gpu: return "rectangle.3.group"
        case .network: return "network"; case .disk: return "internaldrive"; case .battery: return "battery.75"
        case .history: return "clock.arrow.circlepath"; case .benchmark: return "gauge.with.dots.needle.67percent"
        case .autokill: return "xmark.circle"; case .themes: return "paintpalette"
        case .layout: return "square.grid.2x2"; case .alerts: return "bell.badge"; case .about: return "info.circle"
        }
    }
}

// MARK: - Main Settings View
struct SettingsView: View {
    @EnvironmentObject var monitor: MonitorService
    @EnvironmentObject var store:   StoreService
    @EnvironmentObject var alertSvc: AlertService
    @AppStorage("settingsSelectedModule") private var selectedModuleId = "cpu"

    private var selectedModule: SettingsModule { SettingsModule(rawValue: selectedModuleId) ?? .cpu }

    var body: some View {
        NavigationSplitView {
            List(selection: Binding(
                get: { selectedModule },
                set: { selectedModuleId = $0.rawValue }
            )) {
                Section("Modules") {
                    ForEach([SettingsModule.cpu,.ram,.gpu,.network,.disk,.battery]) { m in
                        Label(m.title, systemImage: m.sfSymbol).tag(m)
                    }
                }
                Section("Pro") {
                    ForEach([SettingsModule.history,.benchmark,.autokill,.themes,.layout,.alerts]) { m in
                        HStack {
                            Label(m.title, systemImage: m.sfSymbol)
                            if !store.isPro { Image(systemName: "lock.fill").foregroundColor(.orange).font(.caption) }
                        }.tag(m)
                    }
                }
                Section { Label("About", systemImage: "info.circle").tag(SettingsModule.about) }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 190, maxWidth: 210)
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                    Button("Quit PulseBar") { NSApp.terminate(nil) }
                        .buttonStyle(.plain).padding(.horizontal, 16).padding(.vertical, 10)
                        .foregroundColor(.secondary)
                }
            }
        } detail: {
            Group {
                switch selectedModule {
                case .cpu:       CPUSettingsPanel()
                case .ram:       RAMSettingsPanel()
                case .gpu:       GPUSettingsPanel()
                case .network:   NetworkSettingsPanel()
                case .disk:      DiskSettingsPanel()
                case .battery:   BatterySettingsPanel()
                case .history:   proGate("History")   { HistoryView() }
                case .benchmark: proGate("Benchmark") { BenchmarkView() }
                case .autokill:  proGate("Auto-Kill") { AutoKillView().environmentObject(monitor).environmentObject(alertSvc) }
                case .themes:    proGate("Themes")    { ThemeEditorView() }
                case .layout:    proGate("Layout")    { PopupEditorView() }
                case .alerts:    AlertsPanel().environmentObject(alertSvc)
                case .about:     AboutPanel()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func proGate<V: View>(_ name: String, @ViewBuilder content: () -> V) -> some View {
        #if DEBUG
        content()
        #else
        if store.isPro { content() } else { ProLockedView(featureName: name) }
        #endif
    }
}

// MARK: - CPU Settings
struct CPUSettingsPanel: View {
    @AppStorage("show_cpu")       var shown    = true
    @AppStorage("cpu_interval")   var interval = 3
    @AppStorage("cpu_showIcon")   var showIcon  = true
    @AppStorage("cpu_showLabel")  var showLabel  = true
    @AppStorage("cpu_metric")     var metric    = "Usage Per Core"
    @AppStorage("cpu_style")      var style     = "Bar icon"
    @AppStorage("colorIcon_cpu")  var colored   = true
    var body: some View {
        Form {
            labelHead("CPU", icon: "cpu"); Divider()
            Section("Visibility") { Toggle("Show in menu bar", isOn: $shown) }
            Section("Update interval") { Stepper("\(interval) sec", value: $interval, in: 1...60) }
            Section("Display") {
                Toggle("Show icon",       isOn: $showIcon)
                Toggle("Show label",      isOn: $showLabel)
                Toggle("Colored icon",    isOn: $colored)
                Picker("Metric:", selection: $metric) {
                    Text("Usage").tag("Usage")
                    Text("Usage Per Core").tag("Usage Per Core")
                    Text("Temperature").tag("Temperature")
                }
                Picker("Style:", selection: $style) {
                    Text("Bar icon").tag("Bar icon"); Text("%").tag("%")
                }.pickerStyle(.segmented)
            }
        }.formStyle(.grouped).padding()
    }
}

// MARK: - RAM Settings
struct RAMSettingsPanel: View {
    @AppStorage("show_ram")       var shown    = true
    @AppStorage("ram_interval")   var interval = 3
    @AppStorage("ram_showIcon")   var showIcon  = true
    @AppStorage("ram_showLabel")  var showLabel  = true
    @AppStorage("ram_metric")     var metric    = "Usage"
    @AppStorage("ram_style")      var style     = "Bar icon"
    @AppStorage("colorIcon_ram")  var colored   = true
    var body: some View {
        Form {
            labelHead("RAM", icon: "memorychip"); Divider()
            Section("Visibility") { Toggle("Show in menu bar", isOn: $shown) }
            Section("Update interval") { Stepper("\(interval) sec", value: $interval, in: 1...60) }
            Section("Display") {
                Toggle("Show icon",  isOn: $showIcon); Toggle("Show label",   isOn: $showLabel)
                Toggle("Colored icon", isOn: $colored)
                Picker("Metric:", selection: $metric) {
                    Text("Usage").tag("Usage"); Text("App Memory").tag("App Memory")
                    Text("Wired").tag("Wired"); Text("Compressed").tag("Compressed")
                }
                Picker("Style:", selection: $style) {
                    Text("Bar icon").tag("Bar icon"); Text("%").tag("%")
                }.pickerStyle(.segmented)
            }
        }.formStyle(.grouped).padding()
    }
}

// MARK: - GPU Settings
struct GPUSettingsPanel: View {
    @AppStorage("show_gpu")       var shown    = true
    @AppStorage("gpu_interval")   var interval = 3
    @AppStorage("gpu_showIcon")   var showIcon  = true
    @AppStorage("gpu_showLabel")  var showLabel  = true
    @AppStorage("gpu_metric")     var metric    = "Usage"
    @AppStorage("gpu_style")      var style     = "Bar icon"
    @AppStorage("colorIcon_gpu")  var colored   = true
    var body: some View {
        Form {
            labelHead("GPU", icon: "rectangle.3.group"); Divider()
            Section("Visibility") { Toggle("Show in menu bar", isOn: $shown) }
            Section("Update interval") { Stepper("\(interval) sec", value: $interval, in: 1...60) }
            Section("Display") {
                Toggle("Show icon", isOn: $showIcon); Toggle("Show label", isOn: $showLabel)
                Toggle("Colored icon", isOn: $colored)
                Picker("Metric:", selection: $metric) {
                    Text("Usage").tag("Usage"); Text("Temperature").tag("Temperature"); Text("VRAM").tag("VRAM")
                }
                Picker("Style:", selection: $style) {
                    Text("Bar icon").tag("Bar icon"); Text("%").tag("%")
                }.pickerStyle(.segmented)
            }
        }.formStyle(.grouped).padding()
    }
}

// MARK: - Network Settings
struct NetworkSettingsPanel: View {
    @AppStorage("show_network")      var shown    = true
    @AppStorage("network_interval")  var interval = 3
    @AppStorage("network_showUp")    var showUp    = true
    @AppStorage("network_showDown")  var showDown  = true
    @AppStorage("network_units")     var units    = "Auto"
    @AppStorage("network_interface") var iface    = "Auto"
    @AppStorage("pushover_user")     var pushUser = ""
    @AppStorage("pushover_token")    var pushToken = ""
    var body: some View {
        Form {
            labelHead("Network", icon: "network"); Divider()
            Section("Visibility") { Toggle("Show in menu bar", isOn: $shown) }
            Section("Update interval") { Stepper("\(interval) sec", value: $interval, in: 1...60) }
            Section("Display") {
                Toggle("Show upload speed", isOn: $showUp); Toggle("Show download speed", isOn: $showDown)
                Picker("Speed units:", selection: $units) {
                    Text("Auto").tag("Auto"); Text("B/s").tag("B/s"); Text("KB/s").tag("KB/s"); Text("MB/s").tag("MB/s")
                }
                Picker("Interface:", selection: $iface) {
                    Text("Auto").tag("Auto"); Text("en0").tag("en0"); Text("en1").tag("en1")
                }
            }
            Section("iPhone Push (via Pushover)") {
                TextField("Pushover User Key",  text: $pushUser)
                TextField("Pushover App Token", text: $pushToken)
                Button("Test Push") {
                    Task { await PushNotificationService.shared.send(title:"PulseBar Test", message:"Push notifications working!") }
                }
                Link("Get free Pushover account", destination: URL(string:"https://pushover.net")!)
            }
        }.formStyle(.grouped).padding()
    }
}

// MARK: - Disk Settings
struct DiskSettingsPanel: View {
    @AppStorage("show_disk")          var shown   = true
    @AppStorage("disk_interval")      var interval = 3
    @AppStorage("disk_showTemp")      var showTemp = true
    @AppStorage("disk_showUsage")     var showUsage = true
    @AppStorage("disk_showReadWrite") var showRW   = true
    var body: some View {
        Form {
            labelHead("Disk", icon: "internaldrive"); Divider()
            Section("Visibility") { Toggle("Show in menu bar", isOn: $shown) }
            Section("Update interval") { Stepper("\(interval) sec", value: $interval, in: 1...60) }
            Section("Display") {
                Toggle("Show temperature",      isOn: $showTemp)
                Toggle("Show usage %",          isOn: $showUsage)
                Toggle("Show read/write speed", isOn: $showRW)
            }
        }.formStyle(.grouped).padding()
    }
}

// MARK: - Battery Settings
struct BatterySettingsPanel: View {
    @AppStorage("show_battery")           var shown    = true
    @AppStorage("battery_interval")       var interval = 3
    @AppStorage("battery_showPercentage") var showPct  = true
    @AppStorage("battery_showTime")       var showTime = true
    @AppStorage("battery_showCharging")   var showCharge = true
    @AppStorage("battery_showHealth")     var showHealth = true
    var body: some View {
        Form {
            labelHead("Battery", icon: "battery.75"); Divider()
            Section("Visibility") { Toggle("Show in menu bar", isOn: $shown) }
            Section("Update interval") { Stepper("\(interval) sec", value: $interval, in: 1...60) }
            Section("Display") {
                Toggle("Show percentage",         isOn: $showPct)
                Toggle("Show time remaining",     isOn: $showTime)
                Toggle("Show charging indicator", isOn: $showCharge)
                Toggle("Show health info",        isOn: $showHealth)
            }
        }.formStyle(.grouped).padding()
    }
}

// MARK: - Alerts Panel (combines thresholds + AI + log)
struct AlertsPanel: View {
    @EnvironmentObject var alertSvc: AlertService
    @AppStorage("alert_cpuTemp") var cpuTempT: Double = 80
    @AppStorage("alert_cpuLoad") var cpuLoadT: Double = 85
    @AppStorage("alert_ram")     var ramT:     Double = 90
    @AppStorage("alert_battery") var batT:     Double = 15
    @State private var apiKey:    String = KeychainHelper.get("anthropic_api_key") ?? ""
    @AppStorage("ai_interval")   var aiInterval: Int = 0

    var body: some View {
        Form {
            Section("Thresholds") {
                LabeledContent("CPU Temp °C") { Slider(value: $cpuTempT, in: 60...100, step: 5); Text("\(Int(cpuTempT))°") }
                LabeledContent("CPU Load %")  { Slider(value: $cpuLoadT, in: 50...100, step: 5); Text("\(Int(cpuLoadT))%") }
                LabeledContent("RAM %")       { Slider(value: $ramT,     in: 50...100, step: 5); Text("\(Int(ramT))%")     }
                LabeledContent("Battery %")   { Slider(value: $batT,     in: 5...30,   step: 5); Text("\(Int(batT))%")     }
            }
            Section("AI Analysis (Claude)") {
                SecureField("Anthropic API Key", text: $apiKey)
                    .onChange(of: apiKey) { KeychainHelper.set($0, key: "anthropic_api_key") }
                Text("Get free API key at console.anthropic.com").font(.caption).foregroundColor(.secondary)
                Picker("Auto-analyze every:", selection: $aiInterval) {
                    Text("Never").tag(0); Text("5 min").tag(300); Text("15 min").tag(900); Text("1 hour").tag(3600)
                }
            }
            Section("Alert Log") { AlertLogView().environmentObject(alertSvc).frame(height: 200) }
        }.formStyle(.grouped).padding()
    }
}

// MARK: - About Panel
struct AboutPanel: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.bar.fill").font(.system(size: 64)).foregroundColor(.accentColor)
            Text("PulseBar").font(.title.bold())
            Text("Version 1.0.0").foregroundColor(.secondary)
            Text("Free & Open Source").foregroundColor(.secondary)
            Button("View on GitHub") {
                NSWorkspace.shared.open(URL(string: "https://github.com/Exitze/PulseBar")!)
            }
            Spacer()
        }.frame(maxWidth: .infinity).padding()
    }
}

// MARK: - Helpers
private func labelHead(_ title: String, icon: String) -> some View {
    Label(title, systemImage: icon).font(.title2.bold()).padding(.top, 4).padding(.bottom, 8)
}
