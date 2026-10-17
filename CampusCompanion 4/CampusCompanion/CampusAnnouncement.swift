import Foundation
import CoreData

@objc(CampusAnnouncement)
class CampusAnnouncement: NSManagedObject {
    @NSManaged var title: String
    @NSManaged var date: String
    @NSManaged var category: String
    @NSManaged var priority: String
    @NSManaged var postedBy: String

    @nonobjc class func fetchRequest() -> NSFetchRequest<CampusAnnouncement> {
        NSFetchRequest<CampusAnnouncement>(entityName: "CampusAnnouncement")
    }
}
