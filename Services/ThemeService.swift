import Foundation
import SwiftUI

// MARK: - Feature 9: Theme Service
struct PulseBarTheme: Codable, Identifiable {
    let id: UUID
    var name:            String
    var cpuColor:        String
    var ramColor:        String
    var gpuColor:        String
    var networkColor:    String
    var diskColor:       String
    var batteryColor:    String
    var backgroundColor: String
    var cardColor:       String
    var isBuiltIn:       Bool

    // Color accessors — FIXED: Color(hex:) is non-failable, ?? fallbacks removed
    var cpu:        Color { Color(hex: cpuColor)        }
    var ram:        Color { Color(hex: ramColor)        }
    var gpu:        Color { Color(hex: gpuColor)        }
    var network:    Color { Color(hex: networkColor)    }
    var disk:       Color { Color(hex: diskColor)       }
    var battery:    Color { Color(hex: batteryColor)    }
    var background: Color { Color(hex: backgroundColor) }
    var card:       Color { Color(hex: cardColor)       }

    static let defaultDark = PulseBarTheme(
        id: UUID(), name: "Default Dark",
        cpuColor: "#FF9F0A", ramColor: "#BF5AF2", gpuColor: "#5AC8FA",
        networkColor: "#30D158", diskColor: "#0A84FF", batteryColor: "#32D74B",
        backgroundColor: "#0A0A0A", cardColor: "#111113", isBuiltIn: true)

    static let neon = PulseBarTheme(
        id: UUID(), name: "Neon",
        cpuColor: "#FF0080", ramColor: "#00FF88", gpuColor: "#0080FF",
        networkColor: "#FF8000", diskColor: "#8000FF", batteryColor: "#00FFFF",
        backgroundColor: "#050510", cardColor: "#0A0A20", isBuiltIn: true)

    static let monochrome = PulseBarTheme(
        id: UUID(), name: "Monochrome",
        cpuColor: "#FFFFFF", ramColor: "#CCCCCC", gpuColor: "#AAAAAA",
        networkColor: "#888888", diskColor: "#666666", batteryColor: "#EEEEEE",
        backgroundColor: "#0A0A0A", cardColor: "#141414", isBuiltIn: true)
}

class ThemeService: ObservableObject {
    static let shared = ThemeService()
    @Published var currentTheme: PulseBarTheme = .defaultDark
    @Published var themes: [PulseBarTheme] = [.defaultDark, .neon, .monochrome]

    private init() { loadCurrent() }

    func apply(_ theme: PulseBarTheme) {
        currentTheme = theme
        if let d = try? JSONEncoder().encode(theme) { UserDefaults.standard.set(d, forKey: "currentTheme") }
    }
    func save(custom theme: PulseBarTheme) { themes.append(theme); apply(theme) }

    private func loadCurrent() {
        guard let d = UserDefaults.standard.data(forKey: "currentTheme"),
              let t = try? JSONDecoder().decode(PulseBarTheme.self, from: d) else { return }
        currentTheme = t
    }
}


