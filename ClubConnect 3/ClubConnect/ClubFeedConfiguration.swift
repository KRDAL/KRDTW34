import Foundation

enum ClubFeedConfiguration {
    private static let defaultsKey = "clubFeedURL"

    static var urlString: String {
        UserDefaults.standard.string(forKey: defaultsKey)
            ?? (Bundle.main.object(forInfoDictionaryKey: "ClubFeedURL") as? String) ?? ""
    }

    static func validatedURL(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: trimmed),
              components.scheme?.lowercased() == "https",
              let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil else { return nil }
        return components.url
    }

    static func save(_ text: String) -> Bool {
        guard let url = validatedURL(from: text) else { return false }
        UserDefaults.standard.set(url.absoluteString, forKey: defaultsKey)
        return true
    }
}
