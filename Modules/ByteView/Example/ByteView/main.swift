//
//  main.swift
//  ByteViewDemo
//
//  Created by kiri on 2021/3/5.
//

import RxSwift
import Swinject
import LarkPerf
import BootManager
import AppContainer
import LarkContainer
import LarkLocalizations
import LarkAssembler
import LKLoadable
import ByteView
import LarkNavigation
import BDFishhook
import OfflineResourceManager
import LarkSceneManager
#if canImport(ByteViewHybrid)
import ByteViewHybrid
#endif

var assemblies: [LarkAssemblyInterface] = [BaseAssembly()] + [DemoAssembly()]

final class LarkMainAssembly: FlowBootTask, Identifiable {
    static var identify = "LarkMainAssembly"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        _ = Assembler(assemblies: [], assemblyInterfaces: assemblies, container: BootLoader.container)
        BootLoader.assemblyLoaded = true

        SceneManager.shared.registerMain { window in
            window.backgroundColor = .white
            return DemoTabBarController()
        }
    }
}


private func larkMain() {
    // swiftlint:disable all
    LanguageManager.supportLanguages =
        (Bundle.main.infoDictionary!["SUPPORTED_LANGUAGES"] as! [String]).map { Lang(rawValue: $0) }
    // swiftlint:enable all

    ColdStartup.shared?.do(.main)
    AppStartupMonitor.shared.start(key: .startup)

    LKLoadableManager.run(appMain)
    //fix "Terminated due to signal 13"
    //https://juejin.im/post/5dc3805df265da4d1518efb4
    signal(SIGPIPE, SIG_IGN)
    //fix ttnet gcd crash
    open_bdfishhook()

    NewBootManager.register(LarkMainAssembly.self)

    BootLoader.shared.start(delegate: DemoAppDelegate.self, config: .default)
}

class DemoAppDelegate: AppDelegate {
    override func application(_ application: UIApplication,
                              didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 关闭登录前Rust网络加速
        UserDefaults.standard.set(true, forKey: "disablePassportRustHTTPKey")
        // ByteView 断言后立即崩溃
        _ = NotificationCenter.default.addObserver(forName: Notification.Name("CustomAssertNotification"), object: nil, queue: nil) { notification in
            guard let file = (notification.userInfo?["file"] as? StaticString),
                  let message = (notification.userInfo?["message"] as? String),
                  let line = (notification.userInfo?["line"] as? UInt) else {
                return
            }
            if file.description.contains("Modules/ByteView") {
                fatalError(message, file: file, line: line)
            }
        }
        registerForPushNotifications()
        setupOfflineResourceManager()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - notification
    func registerForPushNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
                print("Permission granted: \(granted)")
                guard granted else { return }
                self?.getNotificationSettings()
            }
    }

    func setupOfflineResourceManager() {
        let config = OfflineResourceConfig(
            appId: "1161",
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            deviceId: "123456789",
            domain: DemoEnv.isStaging ? "gecko.snssdk.com.boe-gateway.byted.org" : "gecko-bd.feishu.cn",
            cacheRootDirectory: NSHomeDirectory() + "/Documents/OfflineResource",
            isBoe: DemoEnv.isStaging
        )
        OfflineResourceManager.setConfig(config)
    }

    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    static let kByteViewUserNotification = "byteView_user_notification_token"
    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        DemoCache.shared.storage.set(token, forKey: Self.kByteViewUserNotification)
    }

    override func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register: \(error)")
    }

    #if canImport(ByteViewHybrid)
    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        if url.absoluteString.hasPrefix("lynx://") {
            return LynxManager.shared.connectDevServer(url)
        }
        return true
    }
    #endif
}

larkMain()
