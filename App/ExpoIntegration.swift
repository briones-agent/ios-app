//
//  Wallabag + Expo Brownfield demo
//
//  Bootstraps the embedded React Native runtime, seeds shared state with
//  a mock reading-list snapshot, and listens for messages from the
//  Reading List Inspector RN screen.
//

#if os(iOS)
    import Foundation
    import UIKit
    import WallabagExpo

    @objc public final class ExpoIntegration: NSObject {
        private static var messagingListenerId: String?

        /// Call from AppDelegate.didFinishLaunchingWithOptions. Initializes
        /// the React Native host, seeds shared state, and subscribes to
        /// messages from RN.
        @objc public static func bootstrap() {
            ReactNativeHostManager.shared.initialize()
            seedSharedState()
            registerMessageHandlers()
        }

        /// Returns a navigation controller hosting the Reading List
        /// Inspector RN screen, ready to be presented from any
        /// UIViewController.
        @objc public static func makeInspectorViewController() -> UIViewController {
            let rn = ReactNativeViewController(moduleName: "main")
            rn.title = "Reading list"
            let nav = UINavigationController(rootViewController: rn)
            nav.modalPresentationStyle = .fullScreen
            let done = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: nav,
                action: #selector(UIViewController.dismissExpoInspector)
            )
            rn.navigationItem.rightBarButtonItem = done
            return nav
        }

        /// Demo helper: when launched with `-WallabagExpoAutoPresent YES`,
        /// present the Reading List Inspector as a full-screen modal so the
        /// integration is recordable without UI automation. Presenting (vs.
        /// taking over the rootVC) keeps the host UI intact and makes the
        /// Done button work naturally.
        @objc public static func scheduleAutoPresentIfRequested() {
            guard UserDefaults.standard.bool(forKey: "WallabagExpoAutoPresent") else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                presentOnKeyWindow()
            }
        }

        private static func presentOnKeyWindow() {
            guard let scene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene }).first,
                  let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first,
                  let root = window.rootViewController
            else { return }
            // If the host has already presented something (e.g. a system
            // permission alert), dismiss it first so the Reading List
            // Inspector becomes the top-most modal.
            var presenter = root
            while let next = presenter.presentedViewController { presenter = next }
            if presenter !== root {
                presenter.dismiss(animated: false) {
                    root.present(makeInspectorViewController(), animated: true)
                }
            } else {
                root.present(makeInspectorViewController(), animated: true)
            }
        }

        private static func seedSharedState() {
            let now = ISO8601DateFormatter().string(from: Date())
            BrownfieldState.set("unreadCount", 18)
            BrownfieldState.set("totalCount", 124)
            BrownfieldState.set("syncStatus", "Idle")
            BrownfieldState.set("lastSyncedAt", now)
            BrownfieldState.set("articles", sampleArticles())
        }

        private static func sampleArticles() -> [[String: Any]] {
            [
                [
                    "id": 1,
                    "title": "The pragmatic case for embedded React Native",
                    "domain": "expo.dev",
                    "thumbnail": "https://images.unsplash.com/photo-1518770660439-4636190af475?w=200&q=70",
                    "minutes": 9,
                    "read": false,
                ],
                [
                    "id": 2,
                    "title": "How wallabag stores articles offline",
                    "domain": "wallabag.org",
                    "thumbnail": "https://images.unsplash.com/photo-1457369804613-52c61a468e7d?w=200&q=70",
                    "minutes": 6,
                    "read": false,
                ],
                [
                    "id": 3,
                    "title": "A short history of read-it-later apps",
                    "domain": "longform.org",
                    "thumbnail": "https://images.unsplash.com/photo-1532012197267-da84d127e765?w=200&q=70",
                    "minutes": 14,
                    "read": true,
                ],
                [
                    "id": 4,
                    "title": "Designing typography for long-form reading",
                    "domain": "type.today",
                    "thumbnail": "https://images.unsplash.com/photo-1455390582262-044cdead277a?w=200&q=70",
                    "minutes": 7,
                    "read": false,
                ],
            ]
        }

        private static func registerMessageHandlers() {
            messagingListenerId = BrownfieldMessaging.addListener { message in
                guard let type = message["type"] as? String else { return }
                switch type {
                case "MARK_NEXT_READ":
                    markNextRead()
                case "SYNC_NOW":
                    syncNow()
                default:
                    break
                }
            }
        }

        private static func markNextRead() {
            guard var articles = BrownfieldState.get("articles") as? [[String: Any]] else { return }
            if let idx = articles.firstIndex(where: { ($0["read"] as? Bool) == false }) {
                articles[idx]["read"] = true
                BrownfieldState.set("articles", articles)
                let unread = articles.filter { ($0["read"] as? Bool) == false }.count
                BrownfieldState.set("unreadCount", unread)
                BrownfieldMessaging.sendMessage([
                    "type": "ARTICLE_MARKED_READ",
                    "id": articles[idx]["id"] as? Int ?? -1,
                ])
            }
        }

        private static func syncNow() {
            BrownfieldState.set("syncStatus", "Syncing…")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                BrownfieldState.set("syncStatus", "Idle")
                BrownfieldState.set("lastSyncedAt", ISO8601DateFormatter().string(from: Date()))
                BrownfieldMessaging.sendMessage(["type": "SYNC_FINISHED"])
            }
        }
    }

    private extension UIViewController {
        @objc func dismissExpoInspector() {
            self.dismiss(animated: true)
        }
    }
#endif
