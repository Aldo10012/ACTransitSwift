import ACTransitSwift
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        ACTransitPlugins.install(token: "ENTER_YOUR_TOKEN")
        return true
    }
}
