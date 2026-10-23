import Foundation

struct AnnouncementDTO: Codable {
    let title: String
    let date: String
    let category: String
    let location: String?
    let priority: String?
}
