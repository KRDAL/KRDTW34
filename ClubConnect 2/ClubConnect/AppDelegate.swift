import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    private(set) var persistentStoreError: Error?

    // The model name must match ClubConnect.xcdatamodeld in the app target.
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ClubConnect")
        container.persistentStoreDescriptions.forEach {
            $0.shouldAddStoreAsynchronously = false
            $0.shouldMigrateStoreAutomatically = true
            $0.shouldInferMappingModelAutomatically = true
        }
        container.loadPersistentStores { [weak self] _, error in
            self?.persistentStoreError = error
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        _ = persistentContainer
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .systemTeal
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
