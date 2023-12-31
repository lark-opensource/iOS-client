//
//  AppDelegate.swift
//  Pods-AppContainerDev
//
//  Created by liuwanlin on 2018/11/15.
//

import Foundation
import UserNotifications
import RxSwift
import BootManager
import LKLoadable
import LarkSceneManager
import LarkStorage
import LKCommonsTracker
import LKCommonsLogging
import UIKit
import Heimdallr
import LarkFoundation
import LarkExtensions

open class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    public var window: UIWindow?
    static private let logger = Logger.log(AppDelegate.self, category: "launch")

    var context: AppInnerContext {
        assert(BootLoader.shared.context != nil)
        return BootLoader.shared.context ?? .default
    }

    public override class func responds(to aSelector: Selector!) -> Bool {
        #if canImport(CryptoKit)
        if #available(iOS 13.0, *), AppConfig.sceneSelectors.contains(aSelector) {
            assert(BootLoader.shared.context != nil)
            return (BootLoader.shared.context ?? .default).config.respondsToSceneSelectors
        }
        #endif
        return super.responds(to: aSelector)
    }

    public override func responds(to aSelector: Selector!) -> Bool {
        #if canImport(CryptoKit)
        if #available(iOS 13.0, *), AppConfig.sceneSelectors.contains(aSelector) {
            return context.config.respondsToSceneSelectors
        }
        #endif
        return super.responds(to: aSelector)
    }

    // MARK: launch
    open func application(_ application: UIApplication, didFinishLaunchingWithOptions
        launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let id = TimeLogger.shared.logBegin(eventName: "AppDelegate")
        LKLoadableManager.run(didFinishLaunch)
        defer {
            TimeLogger.shared.logEnd(identityObject: id, eventName: "AppDelegate")
            BootLoader.isDidFinishLaunchingFinished = true
        }
        if UIApplication.shared.applicationState == .background {
            let event = SlardarEvent(name: "lanch_background", metric: [:], category: [:], extra: [:])
            Tracker.post(event)
        }
        UNUserNotificationCenter.current().delegate = self

        let launchOptions = self.addNotification(to: launchOptions)
        NewBootManager.register(StartApplicationTask.self)
        NewBootManager.shared.context.launchOptions = launchOptions
        NewBootManager.shared.context.blockDispatcherCallBack = {
            self.context.dispatcher.dispatcherBlocking = $0
        }

        #if canImport(CryptoKit)
        if #available(iOS 13.0, *),
           UIApplication.shared.supportsMultipleScenes,
           context.config.respondsToSceneSelectors {
            addApplicationLifeCycleWhenUseScene()
            return true
        }
        #endif

        let window = UIWindow()
        window.windowIdentifier = "AppContainer.AppDelegate.window"
        self.window = window
        self.window?.makeKeyAndVisible()
        NewBootManager.shared.boot(rootWindow: window)
        // 防止启动window没有rootVC crash
        for window in UIApplication.shared.windows where window.rootViewController == nil {
            let storyboard = UIStoryboard(name: "LaunchScreen", bundle: nil)
            let maskView = storyboard.instantiateInitialViewController()?.view ?? UIView()
            let tempVC = UIViewController()
            tempVC.view.addSubview(maskView)
            window.rootViewController = tempVC
        }

        return true
    }

    public func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        HMDStartDetector.markWillFinishingLaunchDate()
        LKLoadableManager.makeWillFinishLaunchingTime()
        return true
    }

    // MARK: lifecycle
    public func applicationDidBecomeActive(_ application: UIApplication) {
        let message = DidBecomeActive(context: context)
        context.dispatcher.send(message: message)
    }

    public func applicationWillResignActive(_ application: UIApplication) {
        let message = WillResignActive(context: context)
        context.dispatcher.send(message: message)
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        // send local notification for test
        if KVPublic.FG.lcMonitor.value() {
            DispatchQueue.global().async {
                let notificationCenter = UNUserNotificationCenter.current()
                let content = UNMutableNotificationContent()
                content.badge = NSNumber(integerLiteral: UIApplication.shared.applicationIconBadgeNumber)
                let request = UNNotificationRequest(identifier: "identify", content: content, trigger: nil)
                notificationCenter.add(request) { _ in
                }
            }
        }
        let message = DidEnterBackground(context: context)
        context.dispatcher.send(message: message)
    }

    public func applicationWillEnterForeground(_ application: UIApplication) {
        let message = WillEnterForeground(context: context)
        context.dispatcher.send(message: message)
    }

    public func applicationWillTerminate(_ application: UIApplication) {
        let event = SlardarEvent(name: "app_willTerminate", metric: [:], category: [:], extra: [:])
        Tracker.post(event)
        let message = WillTerminate(context: context)
        context.dispatcher.send(message: message)
    }

    public func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        let message = DidReceiveMemoryWarning(context: context)
        context.dispatcher.send(message: message)
    }

    // MARK: notification
    open func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let message = DidRegisterForRemoteNotifications(deviceToken: deviceToken, context: context)
        context.dispatcher.send(message: message)
    }

    open func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        let message = DidFailToRegisterForRemoteNotifications(error: error, context: context)
        context.dispatcher.send(message: message)
    }

    public func application(_ application: UIApplication,
                          didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                          fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let notificationCustom = Notification(isRemote: false, userInfo: userInfo)
        let message = DidReceiveBackgroundNotification(notification: notificationCustom, context: context, completionHandler: completionHandler)
        _ = context.dispatcher.send(message: message)
    }

    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                     willPresent notification: UNNotification,
                                     withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        var isRemote = false
        if let trigger = notification.request.trigger {
            if trigger.isKind(of: UNPushNotificationTrigger.self) {
                isRemote = true
            }
        }

        let notificationCustom = Notification(isRemote: isRemote, userInfo: notification.request.content.userInfo)
        let message = DidReceiveNotificationFront(notification: notificationCustom, context: context, request: notification.request, date: notification.date)
        let result = context.dispatcher.send(message: message)
        var notificationOptions: UNNotificationPresentationOptions = []
        var completionCalled: Bool = false
        _ = Observable.zip(result)
            .observeOn(MainScheduler.instance)
            .subscribe({ (event) in
                if completionCalled {
                    return
                }
                if case .next(let options) = event {
                    for option in options {
                        notificationOptions = notificationOptions.union(option)
                    }
                    completionHandler(notificationOptions)
                } else {
                    completionHandler([])
                }
                completionCalled = true
            })
    }

    #if canImport(CryptoKit)
    @available(iOS 13.0, *)
    public func application(_ application: UIApplication,
                          configurationForConnecting connectingSceneSession: UISceneSession,
                          options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        assert(context.config.respondsToSceneSelectors)
        let scene = SceneManager.shared.sceneInfo(session: connectingSceneSession, options: options)
        if !scene.isMainScene() {
            let config = UISceneConfiguration(name: "Other", sessionRole: connectingSceneSession.role)
            return config
        }

        let config = UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
        return config
    }

    @available(iOS 13.0, *)
    public func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        assert(context.config.respondsToSceneSelectors)
        let message = DidDiscardSceneSessions(context: context, sceneSessions: sceneSessions)
        context.dispatcher.send(message: message)
    }
    #endif

    @available(iOS 10.0, *)
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                     didReceive response: UNNotificationResponse,
                                     withCompletionHandler completionHandler: @escaping () -> Void) {
        var isRemote = false
        if let trigger = response.notification.request.trigger {
            if trigger.isKind(of: UNPushNotificationTrigger.self) {
                isRemote = true
            }
        }

        let notificationCustom = Notification(isRemote: isRemote, userInfo: response.notification.request.content.userInfo)
        let message = DidReceiveNotification(notification: notificationCustom, context: context, actionIdentifier: response.actionIdentifier, request: response.notification.request, response: response, date: response.notification.date)
        let result = context.dispatcher.send(message: message)
        var completionCalled: Bool = false
        _ = Observable.zip(result)
            .observeOn(MainScheduler.instance)
            .subscribe({ (event) in
                if completionCalled {
                    return
                }
                if case .next = event {
                    completionHandler()
                } else {
                    completionHandler()
                }
                completionCalled = true
            })
    }

    // MARK: other
    open func applicationSignificantTimeChange(_ application: UIApplication) {
        let message = SignificantTimeChange(context: context)
        context.dispatcher.send(message: message)
    }

    open func application(_ app: UIApplication,
                          open url: URL,
                          options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        let message = OpenURL(url: url, options: options, context: context)
        context.dispatcher.send(message: message)
        return true
    }

    public func application(_ application: UIApplication,
                          performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let message = PerformFetch(context: context, completionHandler: completionHandler)
        context.dispatcher.send(message: message)
    }

    public func application(_ application: UIApplication,
                          performActionFor shortcutItem: UIApplicationShortcutItem,
                          completionHandler: @escaping (Bool) -> Void) {
        let message = PerformAction(shortcutItem: shortcutItem, context: context, completionHandler: completionHandler)
        context.dispatcher.send(message: message)
    }

    public func application(_ application: UIApplication,
                          continue userActivity: NSUserActivity,
                          restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        let message = ContinueUserActivity(userActivity: userActivity, restorationHandler: restorationHandler, context: context)
        context.dispatcher.send(message: message)
        return true
    }
    
    public func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        let message = AllowExtensionPoint(identifier: extensionPointIdentifier)
        let results = context.dispatcher.send(message: message)
        let allowExtension = results.reduce(true) { partialResult, result in
            return partialResult && result
        }
        return allowExtension
    }

    private func addNotification(to launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> [UIApplication.LaunchOptionsKey: Any]? {
        var launchOptions = launchOptions

        var notification: Notification?
        if let userInfo = (launchOptions?[.remoteNotification] as? [AnyHashable: Any]) {
            notification = Notification(isRemote: true, userInfo: userInfo)
        } else if let localNotification = launchOptions?[.localNotification] as? UILocalNotification {
            notification = Notification(isRemote: false, userInfo: localNotification.userInfo ?? [:])
        }

        if launchOptions != nil {
            if let notification = notification {
                launchOptions?[.notification] = notification
            }
        } else if let notification = notification {
            launchOptions = [.notification: notification]
        }

        return launchOptions
    }

    fileprivate struct RecursiveFlag {
        static var isAlreadyCalled: Bool = false
    }

    public func application(_ application: UIApplication,
                            supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {

        func isPad() -> Bool {
            let deviceFamily = Bundle.main.infoDictionary?["UIDeviceFamily"] as? [Int]
            if let uiDeviceFamily = deviceFamily, uiDeviceFamily.count == 1 {
                return uiDeviceFamily.first == 2
            }
            return UIDevice.current.userInterfaceIdiom == .pad
        }

        if isPad() {
            return .all
        }

        if #available(iOS 13.0, *) {
            // iOS 12 及以下可能出现 window 传空的情况，可能会导致后续逻辑判断异常
            // 这里判断如果 window 为 nil，则直接返回 .allButUpsideDown
        } else if window == nil {
            return .allButUpsideDown
        }

        // rootViewController.supportedInterfaceOrientations 会触发此函数的调用导至 死循环 用Flag来避免
        if RecursiveFlag.isAlreadyCalled {
            return .allButUpsideDown
        }

        // Lark 内部 window 的支持转屏的方向之前是指定 window 需要与 keyWindow 取交集
        // 但是引入的 bug 是当 key window 变化之后，尤其是切换过程中，可能会取错 window，所以在 4.5 版本改成了与 rootWindow 取交集
        // 但是这样修改又会导致会议 window 在全屏时无法转屏
        // 考虑到 Lark 取交集的历史逻辑存在肯定有其原因，为了避免引入更多 bug，我们暂时仍然延续这部分逻辑
        // 我们把支持方向逻辑修改为如果 window 为 keyWindow 或者 window 声明自己要控制方向 则直接取 window 支持的方向
        // 如果 window 不是 keyWindow，则取该 window 与 rootWindow 的方向交集
        // 5.4 版本再加上 rootWindow 需要与遮挡 window 方向支持的一致，用来确保状态栏方向正确

        // 获取 window 支持方向
        let getWindowOrientation = { (window: UIWindow?) -> UIInterfaceOrientationMask? in
            guard let window = window else {
                return nil
            }
            if let customTopVC = window.customTopViewController, let vc = customTopVC() {
               return vc.supportedInterfaceOrientations
            } else if let topViewController = window.topViewController {
                return topViewController.supportedInterfaceOrientations
            }
            return nil
        }

        // window 是否决定自己的方向
        let selfControl = { (window: UIWindow?) -> Bool in
            guard let window = window else {
                return false
            }
            return window.isKeyWindow || window.preferControlOrientation
        }

        var orientations = UIInterfaceOrientationMask.allButUpsideDown

        // 判断 window 是否是 keyWindow，或者 window 自己是否要管理方向
        if let window = window, selfControl(window) {
            if let windowSupported = getWindowOrientation(window) {
                RecursiveFlag.isAlreadyCalled = true
                orientations.formIntersection(windowSupported)
            }
        }
        // 取 window 与 rootWindow 交集
        else {
            // 获取 UIApplication delegate 持有 window
            var rootWindow = UIApplication.shared.delegate?.window?.map { $0 }
            // 用于检查 rootWindow 的数组
            var checkWindows = UIApplication.shared.windows
            // 获取 指定 window 所在 scene delegate 持有 window
            if #available(iOS 13.0, *),
               rootWindow == nil,
               let windowScene = window?.windowScene,
               let sceneDelegate = windowScene.delegate as? UIWindowSceneDelegate,
               let sceneRootWindow = sceneDelegate.window {
                rootWindow = sceneRootWindow
                checkWindows = windowScene.windows
            }
            // 尝试获取 KeyWindow
            if rootWindow == nil {
                rootWindow = application.keyWindow
            }

            // 如果当前 window 就是 rootWindow,这里需要额外判断当前是否有 其他 window 完全遮挡 rootWindow
            // 由于 rootWindow会影响状态栏方向，如果存在遮挡，则需要和遮挡的 window 方向保持一致
            // 这里要求遮挡的 window 还必须是自己控制方向(否则它就会又依赖 rootWindow 了)
            if let rootWindow = rootWindow,
               window == rootWindow,
               let blockWindow = checkWindows.first(where: { checkWindow in
                   return checkWindow != rootWindow &&
                    checkWindow.isHidden == false &&
                    checkWindow.frame == rootWindow.frame &&
                    selfControl(checkWindow)
               }),
               let windowSupported = getWindowOrientation(blockWindow) {
                // 如果存在遮挡 window，则 rootWindow 跟随 遮挡 window
                RecursiveFlag.isAlreadyCalled = true
                orientations.formIntersection(windowSupported)
            } else {
                // 先与 rootWindow 取交集
                if let windowSupported = getWindowOrientation(rootWindow) {
                    RecursiveFlag.isAlreadyCalled = true
                    orientations.formIntersection(windowSupported)
                }
                // 再与自己取交集
                if rootWindow != window,
                   let windowSupported = getWindowOrientation(window) {
                    RecursiveFlag.isAlreadyCalled = true
                    orientations.formIntersection(windowSupported)
                }
            }
        }
        RecursiveFlag.isAlreadyCalled = false
        if orientations.isEmpty {
            orientations = .allButUpsideDown
        } else if !orientations.contains(.portrait) { // 保证必有竖屏
            orientations.insert(.portrait)
        }
        return orientations
    }
}

/// Scene 开启时 使用通知监听进程生命周期
extension AppDelegate {
    func addApplicationLifeCycleWhenUseScene() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(observeApplicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(observeApplicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(observeApplicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(observeApplicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
    }

    @objc
    func observeApplicationDidBecomeActive() {
        let message = DidBecomeActive(context: context)
        context.dispatcher.send(message: message)
    }

    @objc
    func observeApplicationWillResignActive() {
        let message = WillResignActive(context: context)
        context.dispatcher.send(message: message)
    }

    @objc
    func observeApplicationDidEnterBackground() {
        let message = DidEnterBackground(context: context)
        context.dispatcher.send(message: message)
    }

    @objc
    func observeApplicationWillEnterForeground() {
        let message = WillEnterForeground(context: context)
        context.dispatcher.send(message: message)
    }

}

private extension UIWindow {

    var topViewController: UIViewController? {
        var top = rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

extension UIWindow {
    private final class AssociatedKeys {
        @UniqueAddress static var preferControlOrientationKey
        @UniqueAddress static var customTopViewControllerKey
    }
    /// 是否需要完全控制 Window 的方向
    ///
    /// AppContainer 内部会根据 KeyWindow / rootWindow 来综合决定当前 Window 支持的方向，
    /// 如果不希望经过这套逻辑的判断，可以将此值设为 true 直接使用系统的旋转逻辑
    /// - Note: 默认为 `false`，为 `true` 时可以通过 TopVC 的 `supportedInterfaceOrientations` 来完全控制 Window 的方向
    public var preferControlOrientation: Bool {
        set {
            objc_setAssociatedObject(self, AssociatedKeys.preferControlOrientationKey,
                                     newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            objc_getAssociatedObject(self, AssociatedKeys.preferControlOrientationKey) as? Bool ?? false
        }
    }

    /// 调用方可以自定义topViewController
    /// AppContainer 内部会根据 KeyWindow / preferControlOrientation 进一步通过组件内部逻辑的topViewController，取到最上层的VC
    /// 如果想自己指定topViewController，可以设置window.customTopViewController，每次在调用时会先判断是否有自定义的VC，如果有，会优先使用这个
    public var customTopViewController: (() -> UIViewController?)? {
        set {
            objc_setAssociatedObject(self, AssociatedKeys.customTopViewControllerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            objc_getAssociatedObject(self, AssociatedKeys.customTopViewControllerKey) as? (() -> UIViewController?)
        }
    }
}
