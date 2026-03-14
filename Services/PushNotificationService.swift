import Foundation

// MARK: - Feature 6: Push Notification Service (Pushover API)
class PushNotificationService {
    static let shared = PushNotificationService()
    private init() {}

    var userKey:  String { UserDefaults.standard.string(forKey: "pushover_user")  ?? "" }
    var appToken: String { UserDefaults.standard.string(forKey: "pushover_token") ?? "" }

    func send(title: String, message: String, priority: Int = 0) async {
        guard !userKey.isEmpty && !appToken.isEmpty else { return }
        let params: [String: Any] = [
            "token": appToken, "user": userKey,
            "title": title, "message": message,
            "priority": priority, "sound": "pushover"
        ]
        var req = URLRequest(url: URL(string: "https://api.pushover.net/1/messages.json")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: params)
        _ = try? await URLSession.shared.data(for: req)
    }
}
