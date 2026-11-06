import Foundation

// The network payload uses the three String keys shown in the classroom example.
// Keeping this value type separate avoids decoding directly into Core Data objects.
struct RemoteAnnouncement: Decodable {
    let title: String
    let date: String
    let category: String

    var normalized: RemoteAnnouncement {
        RemoteAnnouncement(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                           date: date.trimmingCharacters(in: .whitespacesAndNewlines),
                           category: category.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var isValid: Bool {
        !title.isEmpty && !date.isEmpty && !category.isEmpty
    }

    func cacheKey() throws -> String {
        // The feed has no ID. Encoding all fields makes repeated refreshes idempotent.
        try JSONEncoder().encode([title, date, category]).base64EncodedString()
    }
}
