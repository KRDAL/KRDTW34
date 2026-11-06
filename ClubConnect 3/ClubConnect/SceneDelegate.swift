import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        // The scene manifest creates the window from Main.storyboard.
        guard scene is UIWindowScene else { return }
        window?.tintColor = .systemTeal
    }
}
