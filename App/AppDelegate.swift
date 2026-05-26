#if os(iOS)
    import UIKit

    final class AppDelegate: UIResponder, UIApplicationDelegate {
        var window: UIWindow?

        func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
            #if DEBUG
                let args = ProcessInfo.processInfo.arguments

                if args.contains("POPULATE_APPLICATION") {
                    populateApplication()
                }
            #endif

            // Expo brownfield demo: bootstrap the React Native runtime and
            // optionally auto-present the Reading List Inspector (for the
            // recording flow).
            ExpoIntegration.bootstrap()
            ExpoIntegration.scheduleAutoPresentIfRequested()

            return true
        }

        func applicationDidFinishLaunching(_: UIApplication) {
            UIApplication.shared.beginReceivingRemoteControlEvents()
        }

        func applicationWillTerminate(_: UIApplication) {}
    }
#endif
