import Foundation

// The keys mirror clubs.json; Club remains the generated Core Data class.
struct ClubDTO: Codable {
    let name: String
    let category: String
    let iconName: String

    var hasRequiredValues: Bool {
        [name, category, iconName].allSatisfy {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}
