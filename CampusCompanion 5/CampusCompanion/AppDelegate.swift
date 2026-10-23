import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    lazy var persistentContainer: NSPersistentContainer = {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "CampusAnnouncement"
        entity.managedObjectClassName = NSStringFromClass(CampusAnnouncement.self)

        let title = NSAttributeDescription()
        title.name = "title"
        title.attributeType = .stringAttributeType
        title.isOptional = false
        title.defaultValue = ""

        let date = NSAttributeDescription()
        date.name = "date"
        date.attributeType = .stringAttributeType
        date.isOptional = false
        date.defaultValue = ""

        let category = NSAttributeDescription()
        category.name = "category"
        category.attributeType = .stringAttributeType
        category.isOptional = false
        category.defaultValue = ""

        let priority = NSAttributeDescription()
        priority.name = "priority"
        priority.attributeType = .stringAttributeType
        priority.isOptional = false
        priority.defaultValue = "Normal"

        let postedBy = NSAttributeDescription()
        postedBy.name = "postedBy"
        postedBy.attributeType = .stringAttributeType
        postedBy.isOptional = false
        postedBy.defaultValue = ""

        let location = NSAttributeDescription()
        location.name = "location"
        location.attributeType = .stringAttributeType
        location.isOptional = false
        location.defaultValue = ""

        entity.properties = [title, date, category, priority, postedBy, location]
        model.entities = [entity]

        let container = NSPersistentContainer(name: "CampusCompanion", managedObjectModel: model)
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved Core Data error: \(error)")
            }
        }
        return container
    }()

    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            try? context.save()
        }
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
