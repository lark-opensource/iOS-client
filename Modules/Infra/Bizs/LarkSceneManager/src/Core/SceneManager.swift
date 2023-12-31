//
//  SceneManager.swift
//  LarkSceneManager
//
//  Created by 李晨 on 2021/1/17.
//

import Foundation
import UIKit
import RoundedHUD
import LarkStorage
import LarkContainer
import LKCommonsLogging
import UniverseDesignToast

/// scene 配置
@available(iOS 13.0, *)
public protocol SceneConfig {
    /// scene 配置对应的 key
    static var key: String { get }
    /// scene 配置对应的图标
    static func icon() -> UIImage
    /// scene 配置对应的创建 RootVC 的方法
    static func createRootVC(
        scene: UIScene,
        session: UISceneSession,
        options: UIScene.ConnectionOptions,
        sceneInfo: Scene,
        localContext: AnyObject?
    ) -> UIViewController?
    /// scene 根据 sceneInfo 配置对应的图标
    static func contextualIcon(on imageView: UIImageView, with sceneInfo: Scene)
}

@available(iOS 13.0, *)
public extension SceneConfig {
    /// scene 根据 sceneInfo 配置对应的图标，默认空实现
    static func contextualIcon(on imageView: UIImageView, with sceneInfo: Scene) {}
}

/// scene 页面生成 handler
@available(iOS 13.0, *)
public typealias SceneHandler = (
    _ scene: UIScene,
    _ session: UISceneSession,
    _ options: UIScene.ConnectionOptions,
    _ sceneInfo: Scene
) -> UIViewController?

/// scene 页面生成上下文 handler
@available(iOS 13.0, *)
public typealias SceneWithContextHandler = (
    _ scene: UIScene,
    _ session: UISceneSession,
    _ options: UIScene.ConnectionOptions,
    _ sceneInfo: Scene,
    _ localContext: AnyObject?
) -> UIViewController?

/// Scene 激活策略
public enum SceneActiveStrategy {
    /// 任意一个 main scene
    case mainScene
    /// 创建或者激活 scene
    case createOrActive(Scene)
    /// 按照数组顺序优先寻找已经存在的 scene, 如果都不存在，则激活 mainScene
    case preferAndMain([Scene])
    /// 按照数组顺序优先寻找已经存在的 scene, 如果都不存在，则返回当前 scene
    case preferAndCurrent([Scene])
}

/// scene 管理模块
public final class SceneManager {
    let logger = Logger.log(SceneManager.self, category: "Scene.SceneManager")

    /// scene 已经被用户激活之后发出的通知
    public static let SceneActivedByUser = Notification.Name(rawValue: "scene.actived.by.user")

    /// scene manager 单例
    public static let shared: SceneManager = SceneManager()

    /// scene 默认 active error handler
    public static let defaultActiveErrorHandler = { (error: Error, source: SceneFrom) in
        guard let window = source.rootWindow() else {
            return
        }
        RoundedHUD.showFailure(
            with: BundleI18n.LarkSceneManager.Lark_Core_SplitScreenNotSupported,
            on: window
        )
    }

    public var maxNumber: (() -> Int?)?

    /// scene 销毁动画
    public enum DismissalAnimation {
        /// 缩小消失
        case standard
        /// 向上划出
        case commit
        /// 向下划出
        case decline

        @available(iOS 13.0, *)
        func sceneDismissalAnimation() -> UIWindowScene.DismissalAnimation {
            switch self {
            case .standard:
                return .standard
            case .commit:
                return .commit
            case .decline:
                return .decline
            }
        }
    }

    @available(iOS 13.0, *)
    public var windowApplicationScenes: [UIScene] {
        return UIApplication.shared.connectedScenes.filter {
            $0.session.role == .windowApplication
        }
    }

    /// 激活 scene 的回调
    private var callbacks: [Scene: (UIWindow?, Error?) -> Void] = [:]

    /// scene 创建 handler
    private var handlers: [String: Any] = [:]

    /// scene 创建 local contexts
    private var contexts: [Scene: AnyObject] = [:]

    /// scene icon
    var icons: [String: (() -> UIImage)] = [:]

    var contextualIcons: [String: (UIImageView, Scene) -> Void] = [:]

    /// 默认 scene 创建 handler
    private var defaultHandler: ((UIWindow) -> UIViewController)?

    init() {
        if #available(iOS 13.0, *) {
            observeSceneNotification()
        }
    }

    // MARK: - Scene Controller API

    /// 注册主页面的 handler
    /// - Parameter handler: 主界面 handler
    public func registerMain(handler: @escaping (UIWindow) -> UIViewController) {
        self.defaultHandler = handler
    }

    /// 注册 scene 页面 handler
    /// - Parameters:
    ///   - sceneKey: scene 对应的 key
    ///   - handler: scene 页面 handler
    @available(iOS, introduced: 13.0, deprecated, message: "接口已废弃，请尽快改为使用 register(config:) 注册")
    public func register(sceneKey: String, handler: @escaping SceneHandler) {
        self.handlers[sceneKey] = handler
    }

    /// 注册 scene 页面可以获取 localContext 的 handler
    /// - Parameters:
    ///   - sceneKey: scene 对应的 key
    ///   - handler: scene 页面 handler,
    @available(iOS, introduced: 13.0, deprecated, message: "接口已废弃，请尽快改为使用 register(config:) 注册")
    public func register(sceneKey: String, handler: @escaping SceneWithContextHandler) {
        self.handlers[sceneKey] = handler
    }

    /// 注册 scene 配置
    /// - Parameter config: scene 配置，应传入实现 `SceneConfig`的类
    @available(iOS 13.0, *)
    public func register(config: SceneConfig.Type) {
        self.handlers[config.key] = config.createRootVC
        self.icons[config.key] = config.icon
        self.contextualIcons[config.key] = config.contextualIcon
    }

    /// 创建主 scene root viewController
    /// - Parameter window: 将会被设置 rootVC 的 window
    /// - Returns: 返回 rootVC
    public func createMainSceneRootVC(on window: UIWindow) -> UIViewController? {
        return defaultHandler?(window)
    }

    /// 初始化 scene, 解析设置 scene 配置
    /// - Parameters:
    ///   - scene: UIScece 对象
    ///   - session: UISession 对象
    ///   - options: 启动 options
    @available(iOS 13.0, *)
    public func setup(
        scene: UIScene,
        session: UISceneSession,
        options: UIScene.ConnectionOptions) {
        /// 初始化 scene info
        let sceneInfo = SceneManager.shared.sceneInfo(session: session, options: options)
        scene.sceneInfo = sceneInfo
        /// 初始化 scene 激活谓词
        if !sceneInfo.isMainScene(),
           !sceneInfo.isInvalidScene() {
            scene.title = sceneInfo.title
            let conditions = scene.activationConditions
            conditions.canActivateForTargetContentIdentifierPredicate = NSPredicate(value: false)
            let preferPredicate = NSPredicate(format: "self == %@", sceneInfo.targetContentIdentifier)
            conditions.prefersToActivateForTargetContentIdentifierPredicate =
                NSCompoundPredicate(orPredicateWithSubpredicates: [preferPredicate])
            SceneTracker.trackCreateScene(sceneInfo)
        }
        self.deactiveRepetitionIfNeeded(
            scene: sceneInfo,
            currentUIScene: scene,
            currentUISession: session
        )

        NotificationCenter.default.post(
            name: SceneManager.SceneActivedByUser,
            object: scene
        )

        self.checkSceneCount()
    }

    /// 用户系统重新使用 userActivity 激活 scene 之后更新数据
    /// - Parameters:
    ///   - scene: scene 数据模型
    ///   - userActivity: user activity 数据模型，存储 scene 信息
    @available(iOS 13.0, *)
    public func didContinue(
        scene: UIScene,
        userActivity: NSUserActivity) {
        if let originInfo = scene.innerSceneInfo,
           let newInfo = SceneTransformer.transform(activity: userActivity) {
            if originInfo == newInfo {
                scene.sceneInfo = newInfo
                /// 发出用户重复激活统一 scene 的通知
                NotificationCenter.default.post(
                    name: SceneManager.SceneActivedByUser,
                    object: scene
                )
            } else {
                assertionFailure("不应该存在刷新不同 scene 的场景")
            }
        }
    }

    /// 根据 session 配置返回对应的 scene 配置
    /// - Parameters:
    ///   - session: UISession 对象
    ///   - options: 启动 options
    /// - Returns: scene 配置模型
    @available(iOS 13.0, *)
    public func sceneInfo(
        session: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> Scene {
        guard supportsMultipleScenes else {
            return Scene.mainScene()
        }

        var sceneInfo: Scene?
        options.userActivities.forEach { (activity) in
            if sceneInfo == nil,
               let info = SceneTransformer.transform(activity: activity) {
                sceneInfo = info
            }
        }
        if sceneInfo == nil,
           let activity = session.stateRestorationActivity,
           let info = SceneTransformer.transform(activity: activity) {
            sceneInfo = info
        }
        return sceneInfo ?? (
            session.configuration.name == "Default" ? Scene.mainScene() : Scene.invalidScene()
        )
    }

    /// 创建 scene 对应的 rootVC
    /// - Parameters:
    ///   - scene: UIScene 模型
    ///   - session: UISession 模型
    ///   - options: 启动参数
    ///   - window: 将会被设置 rootVC 的 window
    /// - Returns: scene 对应的主页面
    @available(iOS 13.0, *)
    public func sceneViewController(
        scene: UIScene,
        session: UISceneSession,
        options: UIScene.ConnectionOptions,
        window: UIWindow
    ) -> UIViewController? {
        let sceneInfo = scene.sceneInfo
        defer {
            self.contexts[sceneInfo] = nil
        }
        if let handler = handlers[sceneInfo.key] as? SceneHandler,
           let controller = handler(scene, session, options, sceneInfo) {
            return controller
        } else if let handler = handlers[sceneInfo.key] as? SceneWithContextHandler,
            let controller = handler(scene, session, options, sceneInfo, self.contexts[sceneInfo]) {
            return controller
        }
        if !sceneInfo.isMainScene() {
            return UIViewController()
        }
        return createMainSceneRootVC(on: window)
    }

    // MARK: - 管理 API

    /// 放回当前主 scene
    @available(iOS 13.0, *)
    public func mainScene() -> UIScene? {
        return windowApplicationScenes.first { (scene) -> Bool in
            return scene.sceneInfo.isMainScene()
        }
    }

    /// 激活某一个 scene，内部逻辑会优先判断是否已经存在 scene， 如果已经存在，则激活，如果不存在，则创建一个新的 scene
    /// - Parameters:
    ///   - scene:          指定 scene，使用 scene 内部的 key 和 id 来判断 scene 是否相同
    ///   - from:           从哪一个 scene 进行激活，如果传递了，有助于系统判断 scene 的布局
    ///   - localContext:   用于绑定关联对象, 如果创建 scene 的时候设置 localContext，那么可以在 scene 初始化的时候获取 localContext 对象
    ///                     创建 scene 结束后框架将不再持有 localContext
    ///   - keepLayout:     是否保持原有窗口布局，默认为 false
    ///   - callback:       回调函数，用于返回 scene 或者报错
    public func active(scene: Scene, from: SceneFrom?, localContext: AnyObject? = nil,
                       keepLayout: Bool = false, callback: ((UIWindow?, Error?) -> Void)?) {
        guard #available(iOS 13.0, *),
              supportsMultipleScenes else {
            // iOS 13 以下默认返回当前 window
            let rootWindow = from?.rootWindow() ??
                UIApplication.shared.delegate?.window?.map({ $0 })
            callback?(rootWindow, nil)
            return
        }
        callbacks[scene] = callback

        let activity = SceneTransformer.transform(scene: scene)

        let options = UIScene.ActivationRequestOptions()
        options.requestingScene = from?.currentScene()
        if keepLayout, let encodedString = Data(base64Encoded: "X3ByZXNlcnZlTGF5b3V0"), // "_preserveLayout"
           let decodedAttribute = String(data: encodedString, encoding: .utf8) {
            options.setValue(true, forKey: decodedAttribute)
        }
        var session: UISceneSession?
        if let uiScene = self.connectedScene(scene: scene) {
            session = uiScene.session
            /// 已经处于激活状态, 直接回调
            if uiScene.activationState == .foregroundActive {
                /// 更新 sceneInfo
                uiScene.sceneInfo = scene

                callback?(uiScene.rootWindow(), nil)

                self.callbacks[scene] = nil
                /// 已经被激活的场景 不会调用系统接口 需要手动发出通知
                NotificationCenter.default.post(
                    name: SceneManager.SceneActivedByUser,
                    object: uiScene
                )
                self.checkSceneCount()
                return
            }
        } else {
            // 缓存 local context
            self.contexts[scene] = localContext
        }

        UIApplication.shared.requestSceneSessionActivation(
            session,
            userActivity: activity,
            options: options) { [weak self] (error) in
            callback?(nil, error)
            self?.callbacks[scene] = nil
            self?.contexts[scene] = nil
            self?.checkSceneCount()
        }

        // 延时检查是否已经完成 callback
        // 如果 scene 已经创建，无法激活时不会 errorCallback，需要延时检查
        if session != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                if let callback = self?.callbacks[scene] {
                    callback(nil, NSError(domain: "scene.active.error", code: 0, userInfo: nil))
                    self?.callbacks[scene] = nil
                    self?.checkSceneCount()
                }
            }
        }
    }

    /// 按照策略激活对应 scene
    /// - Parameters:
    ///   - strategy: scene 激活策略
    ///  - from: 从哪一个 scene 进行激活
    ///  - localContext: 用于绑定关联对象, 如果创建 scene 的时候设置 localContext，那么可以在 scene 初始化的时候获取 localContext 对象
    ///                  创建 scene 结束后框架将不再持有 localContext
    ///  - callback: 成功响应回调
    ///  - errorHanalder: 错误响应回调，有默认实现，默认会在当前 from 展示 toast 提示用户
    public func active(
        strategy: SceneActiveStrategy,
        from: SceneFrom,
        localContext: AnyObject? = nil,
        callback: ((UIWindow, Scene, SceneFrom) -> Void)?,
        errorHanalder: ((Error, SceneFrom) -> Void)? = SceneManager.defaultActiveErrorHandler) {

        let action = { (scene: Scene) in
            self.active(scene: scene, from: from, localContext: localContext) { (window, error) in
                if let error = error {
                    errorHanalder?(error, from)
                } else if let window = window {
                    callback?(window, scene, from)
                }
            }
        }

        switch strategy {
        case .createOrActive(let scene):
            action(scene)
        case .mainScene:
            action(.mainScene())
        case .preferAndCurrent(let scenes):
            var allScenes = scenes
            if #available(iOS 13.0, *),
               let current = from.currentScene()?.sceneInfo {
                allScenes.append(current)
            } else {
                allScenes.append(.mainScene())
            }
            allScenes.append(.mainScene())
            for scene in allScenes where self.isConnected(scene: scene) {
                action(scene)
                break
            }
        case .preferAndMain(let scenes):
            var allScenes = scenes
            allScenes.append(.mainScene())
            for scene in allScenes where self.isConnected(scene: scene) {
                action(scene)
                break
            }
        }
    }

    /// 销毁 scene
    /// - Parameters:
    ///   - from: 销毁 scene 来源
    ///   - animation: 销毁动画
    public func deactive(
        from: SceneFrom,
        animation: SceneManager.DismissalAnimation = .standard,
        errorHandler: ((Error) -> Void)? = nil
    ) {
        if #available(iOS 13.0, *) {
            guard let scene = from.currentScene() else {
                return
            }
            // 标记是点击清除
            scene.isClickDelete = true
            let options = UIWindowSceneDestructionRequestOptions()
            options.windowDismissalAnimation = animation.sceneDismissalAnimation()
            UIApplication.shared.requestSceneSessionDestruction(
                scene.session,
                options: options) { (error) in
                errorHandler?(error)
            }
        }
    }

    /// 销毁 scene
    /// - Parameters:
    ///   - scene: 销毁 scene 配置
    ///   - animation: 销毁动画
    public func deactive(
        scene: Scene,
        animation: SceneManager.DismissalAnimation = .standard,
        errorHandler: ((Error) -> Void)? = nil
    ) {
        if #available(iOS 13.0, *) {
            if let scene = self.connectedScene(scene: scene) {
                deactive(
                    from: scene,
                    animation: animation,
                    errorHandler: errorHandler
                )
            }
        }
    }

    /// 刷新 scene
    /// - Parameter scene: scene 配置
    public func refresh(scene: Scene) {
        if #available(iOS 13.0, *) {
            if let scene = self.connectedScene(scene: scene) {
                UIApplication.shared.requestSceneSessionRefresh(scene.session)
            }
        }
    }

    /// 判断 scene 是否已经被激活
    /// - Parameter scene: scene 配置
    /// - Returns: 返回是否被激活
    public func isConnected(scene: Scene) -> Bool {
        if #available(iOS 13.0, *) {
            return connectedScene(scene: scene) != nil
        } else {
            return false
        }
    }

    /// 返回 UIScene
    /// - Parameter scene: scene 配置
    /// - Returns: 返回 UIScene
    @available(iOS 13.0, *)
    public func connectedScene(scene: Scene) -> UIScene? {
        return UIApplication.shared.connectedScenes.first { (uiscene) -> Bool in
            return uiscene.sceneInfo == scene
        }
    }

    // MARK: - 支持多窗口开关
    /// 判断是否支持多窗口
    public let supportsMultipleScenes: Bool = {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.supportsMultipleScenes &&
                UIDevice.current.userInterfaceIdiom == .pad &&
                _supportsMultipleScenes
        } else {
            return false
        }
    }()

    /// 更新当前是否支持多任务, 下次启动生效
    public func update(supportsMultipleScenes: Bool) {
        Self._supportsMultipleScenes = supportsMultipleScenes
    }

    /// 更新 scene title
    /// - Parameters:
    ///   - title: 更新的 scene title 数据
    ///   - vc: 指定需要指定的 title 的来源，这里 vc 有两个作用
    ///         第一是需要有 vc 指定对应的 scene, 第二是需要判断 vc 是否是辅助 scene 的 rootVC，只有 rootVC 才能够刷新 titile
    public func updateSceneIfNeeded(title: String, from vc: UIViewController) {
        guard #available(iOS 13, *),
              self.supportsMultipleScenes,
              let scene = vc.currentScene(),
              let sceneInfo = scene.innerSceneInfo,
              !sceneInfo.isMainScene(),
              !title.isEmpty else {
            return
        }
        let checkIsRootVC = { (vc: UIViewController, scene: UIScene) -> Bool in
            guard let window = vc.rootWindow(),
                  scene.rootWindow() == window,
                  let rootVC = window.rootViewController else {
                return false
            }
            if rootVC == vc {
                return true
            } else if let navi = rootVC as? UINavigationController,
                navi.viewControllers.first == vc {
                return true
            }
            return false
        }
        if checkIsRootVC(vc, scene) {
            // 刷新 scene title
            sceneInfo.title = title
            scene.innerSceneInfo = sceneInfo
            scene.title = title
        }
    }

    // 内部保存是否支持多任务
    private static let globalStore = KVStores.udkv(
        space: .global,
        domain: Domain.biz.core.child("SceneManager")
    )
    @KVConfig(key: "supportsMultipleScenes", default: true, store: globalStore)
    private static var _supportsMultipleScenes: Bool

    // MARK: - Private API
    @available(iOS 13.0, *)
    private func deactiveRepetitionIfNeeded(
        scene: Scene,
        currentUIScene: UIScene,
        currentUISession: UISceneSession
    ) {
        UIApplication.shared.connectedScenes.forEach { (uiscene) in
            let sceneInfo = uiscene.innerSceneInfo
            if sceneInfo == scene &&
                currentUISession.configuration.name == uiscene.session.configuration.name &&
                uiscene != currentUIScene {
                UIApplication.shared.requestSceneSessionDestruction(
                    uiscene.session,
                    options: nil,
                    errorHandler: nil
                )
            }
        }
    }

    @available(iOS 13.0, *)
    private func deactiveWhenActivatedIfNeeded(
        scene: UIScene
    ) {
        let sceneInfo = scene.sceneInfo
        if sceneInfo.isInvalidScene() {
            UIApplication.shared.requestSceneSessionDestruction(
                scene.session,
                options: nil,
                errorHandler: nil
            )
        }
    }

    @available(iOS 13.0, *)
    private func checkSceneCount() {
        guard let maxNumber = self.maxNumber?() else { return }
        let scenes = self.windowApplicationScenes.filter { $0 is UIWindowScene && !$0.sceneInfo.isMainScene() }
            .sorted(by: { $0.sceneInfo.activeTime > $1.sceneInfo.activeTime })
        guard scenes.count > maxNumber else { return }
        self.logger.info("checkSceneCount, Scenes count: \(scenes.count), maxNumber: \(maxNumber)")
        scenes.enumerated().filter { (scene) in
            scene.offset >= maxNumber
        }.forEach { (scene) in
            self.logger.info("cdeactive Scene key: \(scene.element.sceneInfo.key)")
            self.deactive(scene: scene.element.sceneInfo)
        }

        if let window = self.mainScene()?.rootWindow() {
            UDToast.showTips(with: BundleI18n.LarkSceneManager.Lark_Core_iPad_SceneClosedForPerformance_Toast, on: window)
        }
    }

    private var didActivateNotiObject: NSObjectProtocol?
    private var didDisconnectNotiObject: NSObjectProtocol?
    private var didChangeKeyWindowNotiObject: NSObjectProtocol?
    /// 上一个 active UIWindowScene
    private weak var lastKeyScene: AnyObject?

    @available(iOS 13.0, *)
    private func observeSceneNotification() {
        /// 进入前台回调
        self.didActivateNotiObject = NotificationCenter.default.addObserver(
            forName: UIScene.didActivateNotification,
            object: nil,
            queue: nil) { [weak self] (noti) in
                let names: [String] = self?.windowApplicationScenes.map({
                    return $0.sceneInfo.key
                }) ?? []
                self?.logger.info("DidActivateNotification, windowScenes Count: \(names.count), \(names)")
                if let scene = noti.object as? UIWindowScene {
                    let sceneInfo = scene.sceneInfo
                    self?.callbacks[sceneInfo]?(scene.rootWindow(), nil)
                    self?.callbacks[sceneInfo] = nil
                    if !scene.refreshd {
                        self?.refresh(scene: sceneInfo)
                        self?.deactiveWhenActivatedIfNeeded(scene: scene)
                        scene.refreshd = true
                    }
                    if !sceneInfo.isMainScene() {
                        SceneTracker.trackShowScene()
                    }
                }
                self?.checkSceneCount()
            }

        /// 销毁清理 window rootVC
        self.didDisconnectNotiObject = NotificationCenter.default.addObserver(
            forName: UIScene.didDisconnectNotification,
            object: nil,
            queue: nil) { [weak self] (noti) in
                let names: [String] = self?.windowApplicationScenes.map({
                    return $0.sceneInfo.key
                }) ?? []
                self?.logger.info("DidDisconnectNotification, windowScenes Count: \(names.count), \(names)")
                if let scene = noti.object as? UIWindowScene,
                   let delegate = scene.delegate as? UIWindowSceneDelegate {
                    delegate.window?.map({ $0 })?.rootViewController = UIViewController()
                    SceneTracker.trackCloseScene(scene)
                }
            }
        /// keyWindow 更改时，更新 scene 的激活时间
        self.didChangeKeyWindowNotiObject = NotificationCenter.default.addObserver(
            forName: UIWindow.didBecomeKeyNotification,
            object: nil,
            queue: nil) { [weak self] noti in
                let names: [String] = self?.windowApplicationScenes.map({
                    return $0.sceneInfo.key
                }) ?? []
                self?.logger.info("DidDisconnectNotification, windowScenes Count: \(names.count), \(names)")
                guard let `self` = self, let window = noti.object as? UIWindow else { return }
                guard window.windowScene != (self.lastKeyScene as? UIWindowScene) ||
                        self.lastKeyScene == nil else { return }
                window.windowScene?.sceneInfo.activeTime = Date()
                self.lastKeyScene = window.windowScene
            }
    }
}
