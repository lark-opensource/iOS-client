//
//  VCScene.swift
//  ByteViewUI
//
//  Created by kiri on 2023/2/21.
//

import Foundation
import ByteViewCommon

public final class VCScene {
    public static var logger: Logger { Logger.windowScene }

    /// vc所在的window
    private static weak var window: UIWindow?
    /// 设置vc的主window
    public static func setWindow(_ window: UIWindow) {
        self.window = window
        if #available(iOS 13, *), let ws = window.windowScene {
            self.preferredWindowScene = ws
        }
    }

    /// 设置vc的主window
    public static func releaseWindow(_ window: UIWindow) {
        guard self.window === window else { return }
        self.window = nil
    }

    /// vc所在的scene
    @available(iOS 13, *)
    public static var windowScene: UIWindowScene? {
        if _isAuxSceneOpening, let ws = auxScene {
            return ws
        }
        if let ws = window?.windowScene {
            return ws
        }
        if let ws = preferredWindowScene, ws.activationState == .foregroundActive {
            return ws
        }
        return UIApplication.shared.topMostScene
    }

    /// 寻找非vc窗口的topMost，可指定是否期待在vc的scene上
    public static func topMost(preferredVcScene: Bool = true) -> UIViewController? {
        if preferredVcScene {
            // 大窗（含辅助窗口），直接返回vc window上的topMost
            if let w = self.window, w.isReferenceWindow {
                return w.rootViewController?.vc.topMost
            }
            // 否则先检查同scene的其他window
            if #available(iOS 13, *), let ws = window?.windowScene, let rw = ws.referenceWindow {
                return rw.rootViewController?.vc.topMost
            } else {
                return UIApplication.shared.referenceWindow?.rootViewController?.vc.topMost
            }
        } else {
            // 先找前台的其他scene
            if #available(iOS 13, *), let ws = window?.windowScene,
               let other = UIApplication.shared.topMostScene(except: ws),
               other.activationState == .foregroundActive || other.activationState == .foregroundInactive {
                return other.referenceWindow?.rootViewController?.vc.topMost
            } else if let w = window, w.isReferenceWindow {
                // 前台没有其他scene，vc又全屏的时候，vc的window会盖在其他window上面，所以topMost依然取vc window
                return w.rootViewController?.vc.topMost
            } else {
                return UIApplication.shared.referenceWindow?.rootViewController?.vc.topMost
            }
        }
    }

    /// 激活当前的 VCScene
    /// - Parameter ignoreWhenActived: 当前已处于 active 状态时是否忽略。true：忽略不处理；false：尝试激活；
    ///
    /// ignoreWhenActived == false，且状态为 foregroundActive 时会判断当前 Scene 是否能激活。
    /// foregroundActive：判断是否有超过 3 个及以上的 Scene，满足则无条件激活；刚好 2 个则判断是否是分屏，分屏下不激活，反之无条件激活。
    /// 非 foregroundActive：无条件激活。
    public static func activateIfNeeded(ignoreWhenActived: Bool = false) {
        if #available(iOS 13.0, *) {
            Util.runInMainThread {
                guard let scene = windowScene else { return }
                var needActive = false
                switch scene.activationState {
                case .foregroundActive:
                    if !ignoreWhenActived {
                        let scenes = UIApplication.shared.connectedScenes
                        let activationCount = scenes.filter { $0.activationState == .foregroundActive }.count
                        needActive = activationCount > 1 && !splitIsAllSelf
                    }
                default:
                    needActive = true
                }

                logger.info("activeVcScene: \(scene), needActive:\(needActive), ignoreWhenActived=\(ignoreWhenActived)")
                if !needActive {
                    return
                }

                let session = scene.session
                let activity = session.stateRestorationActivity
                let options = UIScene.ActivationRequestOptions()
                options.requestingScene = scene
                UIApplication.shared.requestSceneSessionActivation(session,
                                                                   userActivity: activity,
                                                                   options: options) { error in
                    logger.error("requestSceneSessionActivation failed: \(error)")
                }
            }
        }
    }

    public static let didChangeVcSceneNotification = Notification.Name(rawValue: "vc.scene.didChangeVcScene")
    /// UIWindowScene
    public static let previousSceneKey: String = "previousScene"

    /// 转移windowScene，替代self.windowScene = to方法
    /// - parameters:
    ///     - to: 被转移到的scene
    @available(iOS 13, *)
    public static func changeWindowScene(to scene: UIWindowScene) {
        guard let window = self.window, let from = window.windowScene, from != scene else {
            return
        }
        let previousLayoutContext = WindowSceneLayoutContext(interfaceOrientation: from.interfaceOrientation, traitCollection: from.traitCollection, coordinateSpace: from.coordinateSpace)
        window.windowScene = scene
        let isFromAuxScene = from == auxScene
        if isFromAuxScene {
            /// 转移到其他scene后，销毁vc独占的scene
            closeAuxScene()
        }
        NotificationCenter.default.post(name: self.didChangeVcSceneNotification, object: window, userInfo: [previousSceneKey: from])
        let layoutContext = WindowSceneLayoutContext(interfaceOrientation: scene.interfaceOrientation, traitCollection: scene.traitCollection, coordinateSpace: scene.coordinateSpace)
        NotificationCenter.default.post(name: VCNotification.didUpdateWindowSceneNotification, object: window, userInfo: [
            VCNotification.previousLayoutContextKey: previousLayoutContext,
            VCNotification.layoutContextKey: layoutContext
        ])
        logger.info("changeWindowScene finished: isFromAuxScene = \(isFromAuxScene), from = \(from), to = \(scene)")
    }

    /// ByteView统一创建Window的方法
    /// - parameter from: 基于哪个window创建，不传则创建在vc的scene上
    /// - returns: 返回创建成功的window
    public static func createWindow<W: UIWindow>(_ type: W.Type, tag: WindowTag, from: UIWindow? = nil) -> W {
        let window: W
        if #available(iOS 13, *), let ws = from?.windowScene ?? self.windowScene {
            window = W(windowScene: ws)
            if self.preferredWindowScene == nil {
                self.preferredWindowScene = ws
            }
        } else {
            window = W(frame: UIScreen.main.bounds)
        }
        window.tag = tag.rawValue
        if let dependency = UIDependencyManager.dependency {
            var identifier = String(reflecting: type)
            if !identifier.starts(with: "ByteView") {
                identifier = "ByteView.\(identifier)"
            }
            dependency.setWindowIdentifier("\(identifier).\(tag)", for: window)
            dependency.setOrientationControl(for: window, shouldControl: true)
        }
        return window
    }
}

// MARK: - 工具方法
public extension VCScene {
    static var safeAreaInsets: UIEdgeInsets {
        referenceWindow?.safeAreaInsets ?? .zero
    }

    static var bounds: CGRect {
        if let referenceWindow = referenceWindow {
            // iOS 16 以下系统会在某些横屏动画期间返回竖屏 bound
            if Display.phone, isLandscape, referenceWindow.bounds.width < referenceWindow.bounds.height {
                return .init(x: 0, y: 0, width: referenceWindow.bounds.height, height: referenceWindow.bounds.width)
            } else {
                return referenceWindow.bounds
            }
        } else {
            return UIScreen.main.bounds
        }
    }

    static var rootTraitCollection: UITraitCollection? {
        referenceWindow?.traitCollection
    }

    static var displayScale: CGFloat {
        if let scale = rootTraitCollection?.displayScale {
            return scale > 0 ? scale : 1.0
        }
        return 1.0
    }

    static var isRegular: Bool {
        rootTraitCollection?.isRegular ?? false
    }

    static var splitIsAllSelf: Bool {
        guard #available(iOS 13.0, *) else {
            return false
        }

        let scenes = UIApplication.shared.validWindowScenes.filter { $0.activationState == .foregroundActive }
        let activationCount = scenes.count
        if activationCount != 2 {
            return false
        }

        var isSplit = 0
        scenes.forEach { scene in
            let screenBounds = scene.screen.bounds
            if let window = scene.windows.first(where: { $0.isKeyWindow }) {
                let screenHeight = screenBounds.size.height
                let windowHeight = window.bounds.size.height
                isSplit += (screenHeight == windowHeight) ? 1 : 0
            }
        }

        return isSplit == 2
    }

    static var isLandscape: Bool {
        if #available(iOS 13.0, *) {
            if let scene = windowScene {
                return scene.interfaceOrientation.isLandscape
            } else if let scene = UIApplication.shared.connectedScenes.first(where: { (scene) -> Bool in
                return scene.activationState == .foregroundActive && scene.session.role == .windowApplication
            }) as? UIWindowScene {
                return scene.interfaceOrientation.isLandscape
            }
            return Display.pad ? true : false
        } else {
            return UIApplication.shared.statusBarOrientation.isLandscape
        }
    }

    static var isPhoneLandscape: Bool {
        Display.phone && isLandscape
    }

    static var isPhonePortrait: Bool {
        Display.phone && !isLandscape
    }

    private static var referenceWindow: UIWindow? {
        if let w = self.window, w.isReferenceWindow {
            return w
        } else if #available(iOS 13, *), let ws = windowScene {
            return ws.referenceWindow
        } else if let w = UIApplication.shared.windows.first(where: { $0.isReferenceWindow }) {
            return w
        } else {
            return nil
        }
    }

}

/// 辅助窗口
public extension VCScene {
    /// window scenes是否全部完成状态转换
    static var isSceneTransitionFinished: Bool {
        UIApplication.shared.isSceneTransitionFinished
    }

    @available(iOS 13, *)
    static var topMostScene: UIWindowScene? {
        UIApplication.shared.topMostScene
    }

    static var supportsMultipleScenes: Bool {
        if #available(iOS 13, *), Display.pad, !Util.isiOSAppOnMacSystem, let dep = UIDependencyManager.dependency {
            return dep.supportsMultipleScenes
        } else {
            return false
        }
    }

    static func openScene(info: SceneInfo, localContext: AnyObject? = nil, completion: ((UIWindow?, Error?) -> Void)?) {
        guard #available(iOS 13, *), let dependency = UIDependencyManager.dependency, dependency.supportsMultipleScenes else {
            completion?(nil, OpenSceneError.multipleScenesNotSupported)
            return
        }
        dependency.openScene(from: self.window, info: info, localContext: localContext, completion: completion)
    }

    /// 重新打开 UIScene，比如从后台拉到前台，从非前置切换到最前置窗口等。
    /// - Parameters:
    ///   - scene: 需要重新展示的 UIScene
    ///   - errorHandler: 错误回调
    @available(iOS 13.0, *)
    static func reopenScene(_ scene: UIScene, errorHandler: ((Error) -> Void)? = nil) {
        let session = scene.session
        let options = UIScene.ActivationRequestOptions()
        options.requestingScene = scene
        UIApplication.shared.requestSceneSessionActivation(session,
                                                           userActivity: session.stateRestorationActivity,
                                                           options: options,
                                                           errorHandler: errorHandler)
    }

    @available(iOS 13.0, *)
    static func closeScene(_ scene: UIWindowScene, errorHandler: ((Error) -> Void)? = nil) {
        scene.isClosedScene = true
        let options = UIWindowSceneDestructionRequestOptions()
        options.windowDismissalAnimation = .standard
        UIApplication.shared.requestSceneSessionDestruction(scene.session, options: options, errorHandler: errorHandler)
        logger.info("\(scene.isVcAuxScene ? "closeAuxScene" : "closeScene"): \(scene.debugDescription)")
    }

    /// 销毁 scene
    /// - Parameters:
    ///   - scene: SceneInfo
    ///   - animation: 销毁动画样式
    ///   - errorHandler: 错误回调
    static func closeScene(_ scene: SceneInfo, errorHandler: ((Error) -> Void)? = nil) {
        guard #available(iOS 13, *), let dependency = UIDependencyManager.dependency,
              dependency.supportsMultipleScenes, let ws = dependency.connectedScene(scene: scene) as? UIWindowScene else {
            errorHandler?(OpenSceneError.multipleScenesNotSupported)
            return
        }
        closeScene(ws, errorHandler: errorHandler)
    }

    @available(iOS 13.0, *)
    static func deactive(from: UIScene, animation: SceneDismissalAnimation = .standard, errorHandler: ((Error) -> Void)? = nil) {
        guard let dependency = UIDependencyManager.dependency, dependency.supportsMultipleScenes else {
            errorHandler?(OpenSceneError.multipleScenesNotSupported)
            return
        }
        dependency.deactive(from: from, animation: animation, errorHandler: errorHandler)
    }

    /// 判断 scene 是否已经被激活
    /// - Parameter scene: SceneInfo 配置
    /// - Returns: 返回是否被激活
    static func isConnected(scene: SceneInfo) -> Bool {
        guard #available(iOS 13, *), let dependency = UIDependencyManager.dependency, dependency.supportsMultipleScenes else {
            return false
        }
        return dependency.isConnected(scene: scene)
    }

    /// 返回 UIScene
    /// - Parameter scene: SceneInfo 配置
    /// - Returns: 返回 UIScene
    @available(iOS 13.0, *)
    static func connectedScene(scene: SceneInfo) -> UIScene? {
        guard let dependency = UIDependencyManager.dependency, dependency.supportsMultipleScenes else {
            return nil
        }
        return dependency.connectedScene(scene: scene)
    }

    /// 判断 scene 是否有效
    /// - Parameter scene: 需要判断的 UIWindowScene
    /// - Returns: 返回是否有效
    @available(iOS 13.0, *)
    static func isValidScene(scene: UIWindowScene) -> Bool {
        guard let dependency = UIDependencyManager.dependency, dependency.supportsMultipleScenes else {
            return false
        }
        return dependency.isValidScene(scene: scene)
    }

    static var isAuxSceneOpen: Bool {
        if #available(iOS 13, *) {
            return _isAuxSceneOpening && auxScene != nil
        } else {
            return false
        }
    }

    static func openAuxScene(id: String, title: String, completion: ((UIWindow?, Error?) -> Void)? = nil) {
        Util.runInMainThread {
            guard #available(iOS 13, *), supportsMultipleScenes else {
                completion?(nil, OpenSceneError.multipleScenesNotSupported)
                return
            }
            guard let window = self.window else {
                completion?(nil, OpenSceneError.windowNotFound)
                logger.warn("openAuxScene not supported")
                return
            }
            var info = SceneInfo(key: .vc, id: id)
            info.windowType = "vc"
            info.createWay = "button"
            info.title = title
            _openAuxScene(info: info, window: window, completion: completion)
        }
    }

    static func closeAuxScene() {
        guard #available(iOS 13, *), let scene = auxScene else {
            _isAuxSceneOpening = false
            return
        }
        _isAuxSceneOpening = false
        auxScene = nil
        closeScene(scene)
        if let to = UIApplication.shared.topMostScene {
            changeWindowScene(to: to)
        }
    }

    static var canCloseAuxScene: () -> Bool = { true }

    /// 当会议结束时，关闭vc独占的scene。兼容忙线响铃逻辑
    static func closeAuxSceneIfNeeded(shouldClose: @escaping () -> Bool) {
        Util.runInMainThread {
            logger.info("closeAuxSceneIfNeeded: isOpen = \(VCScene.isAuxSceneOpen)")
            /// retry ~5s
            _closeAuxSceneIfNeeded(retry: 15, shouldClose: shouldClose)
        }
    }

    @available(iOS 13, *)
    private static func _openAuxScene(info: SceneInfo, window: UIWindow, completion: ((UIWindow?, Error?) -> Void)?) {
        logger.info("openAuxScene start, \(info)")
        window.alpha = 0
        window.isHidden = true
        VCAuxSceneService.isCreatingAuxScene = true
        let wrapper: (UIWindow?, Error?) -> Void = { [weak window] (w, error) in
            VCAuxSceneService.isCreatingAuxScene = false
            window?.isHidden = false
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.25, animations: {
                window?.alpha = 1.0
            }, completion: { _ in
                completion?(w, error)
            })
        }
        openScene(info: info) { [weak window] (w, error) in
            if let error = error {
                logger.error("openAuxScene failed: \(error)")
                wrapper(nil, error)
            } else if let w = w, let ws = w.windowScene {
                if window != nil {
                    self._isAuxSceneOpening = true
                    self.auxScene = ws
                    ws.isVcAuxScene = true
                    logger.info("openAuxScene success: \(ws.debugDescription)")
                    self.changeWindowScene(to: ws)
                    wrapper(w, error)
                } else {
                    closeScene(ws)
                    wrapper(nil, OpenSceneError.windowNotFound)
                }
            } else {
                wrapper(nil, OpenSceneError.unknown)
            }
        }
    }

    private static func _closeAuxSceneIfNeeded(retry: Int, shouldClose: @escaping () -> Bool) {
        if !isAuxSceneOpen { return }
        if shouldClose() {
            closeAuxScene()
        } else if retry > 0 {
            // nolint-next-line: magic number
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(350)) {
                self._closeAuxSceneIfNeeded(retry: retry - 1, shouldClose: shouldClose)
            }
        }
    }

    /// 是否vc独占一个scene
    private static var _isAuxSceneOpening = false
    /// vc独占的scene
    @available(iOS 13.0, *)
    private static weak var auxScene: UIWindowScene?
}

/// preferredWindowScene
public extension VCScene {
    static func setPreferredWindowScene(from: UIWindow?) {
        if #available(iOS 13.0, *) {
            self.preferredWindowScene = from?.windowScene
        }
    }

    @available(iOS 13.0, *)
    private static weak var preferredWindowScene: UIWindowScene?
}

private extension UIApplication {
    var referenceWindow: UIWindow? {
        if #available(iOS 13, *) {
            return topMostScene?.referenceWindow
        } else if let ow = delegate?.window, let w = ow {
            return w
        } else if let kw = keyWindow, kw.isReferenceWindow {
            return kw
        } else {
            let bounds = UIScreen.main.bounds
            return windows.first(where: { $0.bounds == bounds })
        }
    }
}

@available(iOS 13.0, *)
private extension UIApplication {
    /// foreground keyWindow -> active -> foreground -> keyWindow -> any
    var topMostScene: UIWindowScene? {
        topMostScene(candidates: validWindowScenes)
    }

    func topMostScene(except scene: UIWindowScene) -> UIWindowScene? {
        topMostScene(candidates: validWindowScenes.filter({ $0 != scene }))
    }

    private func topMostScene(candidates scenes: [UIWindowScene]) -> UIWindowScene? {
        let activeScenes = scenes.filter { $0.activationState == .foregroundActive }
        if let scene = activeScenes.first(where: { $0.windows.contains { $0.isKeyWindow } }) {
            return scene
        }
        if let scene = activeScenes.first {
            return scene
        }
        let inactiveScenes = scenes.filter { $0.activationState == .foregroundInactive }
        if let scene = inactiveScenes.first(where: { $0.windows.contains { $0.isKeyWindow } }) {
            return scene
        }
        if let scene = inactiveScenes.first {
            return scene
        }
        if let scene = scenes.first(where: { $0.windows.contains { $0.isKeyWindow } }) {
            return scene
        }
        return scenes.first
    }

    var validWindowScenes: [UIWindowScene] {
        connectedScenes.compactMap { $0 as? UIWindowScene }.filter { !$0.isClosedScene && VCScene.isValidScene(scene: $0) }
    }
}

@available(iOS 13.0, *)
public extension UIWindowScene {
    var isClosedScene: Bool {
        get {
            session.userInfo?["vc.isClosedScene"] as? Bool ?? false
        }
        set {
            var userInfo = session.userInfo ?? [:]
            userInfo["vc.isClosedScene"] = newValue
            session.userInfo = userInfo
        }
    }

    var isVcAuxScene: Bool {
        get {
            session.userInfo?["vc.isVcAuxScene"] as? Bool ?? false
        }
        set {
            var userInfo = session.userInfo ?? [:]
            userInfo["vc.isVcAuxScene"] = newValue
            session.userInfo = userInfo
        }
    }
}

@available(iOS 13.0, *)
private extension UIWindowScene {
    /// 基准window，scene的delegate或第一个全屏window
    var referenceWindow: UIWindow? {
        if let ow = (self.delegate as? UIWindowSceneDelegate)?.window, let w = ow {
            return w
        } else if #available(iOS 15.0, *), let kw = self.keyWindow, kw.isReferenceWindow {
            return kw
        } else if let kw = self.windows.first(where: { $0.isKeyWindow }), kw.isReferenceWindow {
            return kw
        } else {
            let bounds = CGRect(origin: .zero, size: coordinateSpace.bounds.size)
            return windows.first(where: { $0.bounds == bounds })
        }
    }
}

private extension UIWindow {
    /// 是否可作为基准window
    var isReferenceWindow: Bool {
        if #available(iOS 13, *), let ws = self.windowScene {
            return self.bounds == CGRect(origin: .zero, size: ws.coordinateSpace.bounds.size)
        } else if let ow = UIApplication.shared.delegate?.window, let w = ow {
            return self.bounds == CGRect(origin: .zero, size: w.bounds.size)
        } else {
            return self.bounds == CGRect(origin: .zero, size: screen.bounds.size)
        }
    }
}

private extension Logger {
    static let windowScene = Logger.getLogger("WindowScene")
}

private extension UIApplication {
    /// window scenes是否全部完成状态转换
    var isSceneTransitionFinished: Bool {
        if #available(iOS 13.0, *) {
            return validWindowScenes.allSatisfy { $0.activationState != .foregroundInactive }
        } else {
            return applicationState != .inactive
        }
    }
}

@available(iOS 13, *)
public final class VCAuxSceneService {
    fileprivate static var isCreatingAuxScene = false

    public static func icon() -> UIImage {
        BundleResources.ByteViewUI.Meet.icon_vc_scene
    }

    public static func createRootViewController(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions, sceneInfo: SceneInfo, localContext: AnyObject?) -> UIViewController? {
        if self.isCreatingAuxScene {
            Logger.ui.info("opening new scene, info = \(sceneInfo)")
            let vc = UIViewController()
            vc.view.backgroundColor = .white
            return vc
        } else {
            Logger.ui.error("open new scene cancelled: meeting & window not ready, info = \(sceneInfo)")
            return nil
        }
    }
}

@available(iOS 13.0, *)
public protocol VCSideBarSceneProvider: AnyObject {
    func createViewController(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions, sceneInfo: SceneInfo, localContext: AnyObject?) -> UIViewController?
}

@available(iOS 13.0, *)
extension VCSideBarSceneProvider {
    func createViewController(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions, sceneInfo: SceneInfo, localContext: AnyObject?) -> UIViewController? {
        return nil
    }
}

@available(iOS 13.0, *)
public final class VCSideBarSceneService {
    private final class WeakProvider {
        weak var ref: VCSideBarSceneProvider?

        init(ref: VCSideBarSceneProvider? = nil) {
            self.ref = ref
        }
    }

    private static let shared = VCSideBarSceneService()
    @RwAtomic private var providers = [SceneInfo: WeakProvider]()

    public static func addProvider<T: VCSideBarSceneProvider>(_ provider: T, for sceneInfo: SceneInfo) {
        Self.shared.providers[sceneInfo] = WeakProvider(ref: provider)
    }

    public static func removeProvider(for sceneInfo: SceneInfo) {
        Self.shared.providers.removeValue(forKey: sceneInfo)
    }

    public static func createRootViewController(scene: UIScene,
                                                session: UISceneSession,
                                                options: UIScene.ConnectionOptions,
                                                sceneInfo: SceneInfo,
                                                localContext: AnyObject?) -> UIViewController?
    {
        if let provider = Self.shared.providers[sceneInfo], let ref = provider.ref {
            return ref.createViewController(scene: scene, session: session, options: options, sceneInfo: sceneInfo, localContext: localContext)
        }
        Logger.ui.error("no provider for sceneInfo \(sceneInfo)")
        assertionFailure("no provider for sceneInfo \(sceneInfo)")
        return nil
    }
}

private enum OpenSceneError: String, Error, CustomStringConvertible {
    case unknown
    case windowNotFound
    case dependencyNotFound
    case multipleScenesNotSupported

    var description: String { "OpenSceneError.\(rawValue)" }
}
