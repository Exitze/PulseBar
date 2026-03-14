import SwiftUI

// MARK: - Feature 5: Auto-Kill View
struct AutoKillView: View {
    @StateObject private var svc = AutoKillService.shared
    @EnvironmentObject var monitor: MonitorService
    @State private var showAdd = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label("Use with caution — processes are force-quit", systemImage: "exclamationmark.triangle.fill")
                .font(.caption).foregroundColor(.orange)
                .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 8)
            Form {
                Section {
                    if svc.rules.isEmpty {
                        Text("No rules yet. Tap '+' to add one.").foregroundColor(.secondary)
                    }
                    ForEach($svc.rules) { $rule in
                        HStack {
                            Toggle("", isOn: $rule.isEnabled).labelsHidden()
                            VStack(alignment: .leading, spacing: 2) {
                                Text(rule.processName).font(.system(size: 13, weight: .semibold))
                                Text("Kill if >\(Int(rule.cpuThreshold))% CPU for >\(rule.durationSeconds)s")
                                    .font(.caption).foregroundColor(.secondary)
                                if let t = rule.lastTriggered {
                                    Text("Last killed: \(t.formatted(date: .abbreviated, time: .shortened)) (\(rule.killCount)×)")
                                        .font(.caption2).foregroundColor(.orange)
                                }
                            }
                            Spacer()
                        }
                    }
                    .onDelete { svc.deleteRules(at: $0) }
                } header: {
                    HStack {
                        Text("Kill Rules")
                        Spacer()
                        Button { showAdd = true } label: { Image(systemName: "plus") }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .sheet(isPresented: $showAdd) {
            AddKillRuleSheet(running: monitor.topCPUProcesses.map(\.name))
        }
    }
}

struct AddKillRuleSheet: View {
    @Environment(\.dismiss) var dismiss
    var running: [String]
    @State private var name      = ""
    @State private var threshold = 80.0
    @State private var duration  = 120

    var body: some View {
        VStack(spacing: 0) {
            Text("Add Kill Rule").font(.title3.bold()).padding()
            Form {
                Section("Process Name") {
                    TextField("e.g. Google Chrome Helper", text: $name)
                    if !running.isEmpty {
                        Picker("Running process", selection: $name) {
                            ForEach(running.prefix(15), id: \.self) { Text($0).tag($0) }
                        }
                    }
                }
                Section("CPU Threshold: \(Int(threshold))%") {
                    Slider(value: $threshold, in: 50...100, step: 5)
                }
                Section("Duration") {
                    Stepper("\(duration) seconds", value: $duration, in: 30...600, step: 30)
                }
            }.formStyle(.grouped)
            HStack {
                Button("Cancel") { dismiss() }.buttonStyle(.borderless)
                Spacer()
                Button("Add Rule") {
                    let rule = KillRule(id: UUID(), processName: name, cpuThreshold: threshold,
                                        durationSeconds: duration, isEnabled: true)
                    AutoKillService.shared.addRule(rule); dismiss()
                }.buttonStyle(.borderedProminent).disabled(name.isEmpty)
            }.padding()
        }
        .frame(width: 400, height: 480)
    }
}

// MARK: - Feature 8: Alert Log View
struct AlertLogView: View {
    @EnvironmentObject var alertSvc: AlertService
    @State private var expanded: Set<UUID> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Alert History  (\(alertSvc.recentAlerts.count))")
                    .font(.headline).padding()
                Spacer()
                Button("Clear Log") { alertSvc.clearLog() }
                    .foregroundColor(.red).padding()
            }
            List(alertSvc.recentAlerts) { alert in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: alert.severity == .critical ? "exclamationmark.triangle.fill" : "exclamationmark.circle")
                            .foregroundColor(alert.severity == .critical ? .red : .orange)
                        Text(alert.title).font(.system(size: 12, weight: .semibold))
                        Spacer()
                        Text(alert.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2).foregroundColor(.secondary)
                    }
                    if expanded.contains(alert.id) {
                        Text(alert.body).font(.caption).foregroundColor(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if expanded.contains(alert.id) { expanded.remove(alert.id) }
                    else { expanded.insert(alert.id) }
                }
            }
            .listStyle(.plain)
        }
    }
}
