//
//  Router.swift
//  ByteView
//
//  Created by zfpan on 2020/9/24.
//

import Foundation
import RxSwift
import RxRelay
import UIKit
import ByteViewUI
import ByteViewMeeting
import ByteViewTracker
import LarkShortcut

protocol RouteBody {
    static var pattern: String { get }
}

class RouteHandler<T: RouteBody> {
    func handle(_ body: T) -> UIViewController? {
        methodNotImplemented()
    }
}

final class RouteFrom {
    private weak var _vc: UIViewController?
    private weak var _view: UIView?
    private weak var _window: UIWindow?
    init(_ vc: UIViewController) {
        self._vc = vc
    }

    init(_ view: UIView) {
        if let w = view as? UIWindow {
            self._window = w
        } else {
            self._view = view
        }
    }

    var from: UIViewController? {
        assertMain()
        if let vc = _vc {
            return vc
        } else if let root = self.window?.rootViewController {
            return root
        } else {
            return nil
        }
    }

    var window: UIWindow? {
        assertMain()
        if let w = self._window {
            return w
        } else if let view = self._view {
            return view.window
        } else if let vc = self._vc {
            return vc.view.window
        }
        return nil
    }
}

enum RouteError: Error {
    case unknown
    case fromNotFound
    case resourceNotFound
    case navigationNotFound
    case notImplemented
    case notPresentable
}

protocol RouterListener: AnyObject {
    func didChangeWindow(_ window: FloatingWindow?)
    func didChangeWindowFloatingBeforeAnimation(_ isFloating: Bool, window: FloatingWindow?)
    func didChangeWindowFloatingAfterAnimation(_ isFloating: Bool, window: FloatingWindow?)
}

final class Router {
    private let sessionId: String
    private let meetingDependency: MeetingDependency
    private weak var session: MeetingSession?
    private var dependency: RouteDependency { meetingDependency.router }
    private var larkUtil: LarkDependency { meetingDependency.lark }
    private var setting: MeetingSettingManager? { session?.service?.setting }
    /// 通过 openByteViewScene 打开的 scenes
    private let sideBarScenes: NSHashTable<UIWindow> = NSHashTable.weakObjects()
    let logger: Logger
    init(session: MeetingSession, dependency: MeetingDependency) {
        self.sessionId = session.sessionId
        self.meetingDependency = dependency
        self.session = session
        self.logger = Logger.router.withContext(sessionId).withTag("[Router(\(sessionId))]")
        _ = Self.initializeOnce
        dependency.shortcut?.registerHandler(self, for: .vc.floatWindow, isWeakReference: true)
        logger.info("init Router")
    }

    deinit {
        logger.info("deinit Router, hasWindow: \(window != nil)")
        if let w = window {
            self._dismissWindow(window: w, animated: false, completion: nil)
        }
    }

    private(set) var window: FloatingWindow?
    private let listeners = Listeners<RouterListener>()

    private(set) lazy var pipActiveView: UIView = {
        let activeView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0.1, height: 0.1)))
        activeView.isUserInteractionEnabled = false
        return activeView
    }()

    private static let initializeOnce: Void = {
        _ = Router.handlers
    }()

    // register
    private static let handlers: [ObjectIdentifier: (RouteBody) -> UIViewController?] = {
        var map = [ObjectIdentifier: (RouteBody) -> UIViewController?]()
        var patterns = [String: RouteBody.Type]()
        func register<T: RouteBody>(_ type: T.Type, factory: @autoclosure @escaping () -> RouteHandler<T>) {
            map[ObjectIdentifier(type)] = { (body) in
                guard let body = body as? T else { return nil }
                return factory().handle(body)
            }
        }
        register(CallOutBody.self, factory: CallOutHandler())
        register(CallInBody.self, factory: CallInHandler())
        register(PreviewBody.self, factory: PreviewHandler())
        register(InMeetBody.self, factory: InMeetHandler())
        register(InMeetOfPhoneCallBody.self, factory: InMeetOfPhoneCallHandler())
        register(WebinarRoleTransitionBody.self, factory: WebinarRoleTransitionHandler())
        register(CallKitAnsweringBody.self, factory: CallKitAnsweringHandler())
        register(ConnectFailedBody.self, factory: ConnectFailedHandler())
        register(LobbyBody.self, factory: LobbyHandler())
        register(PrelobbyBody.self, factory: PrelobbyHandler())
        Logger.router.info("handlers count = \(map.count)")
        return map
    }()

    func addListener(_ listener: RouterListener, fireImmediately: Bool = false) {
        listeners.addListener(listener)
        if fireImmediately {
            listener.didChangeWindow(window)
            listener.didChangeWindowFloatingBeforeAnimation(isFloating, window: window)
            listener.didChangeWindowFloatingAfterAnimation(isFloating, window: window)
        }
    }

    func removeListener(_ listener: RouterListener) {
        listeners.removeListener(listener)
    }
}

// MARK: - present & dismiss
extension Router {
    private func viewController<T: RouteBody>(for body: T) -> UIViewController? {
        if let vc = Self.handlers[ObjectIdentifier(T.self)]?(body) {
            return vc
        }
        self.logger.error("Can't create vc, body = \(body)")
        return nil
    }

    func push<T: RouteBody>(body: T, from: UIViewController? = nil, animated: Bool = true,
                            file: String = #fileID, function: String = #function, line: Int = #line,
                            completion: ((UIViewController?, Error?) -> Void)? = nil) {
        Util.runInMainThread { [weak self] in
            guard let self = self, let fromVC = self.calculateFrom(context: from) else {
                self?.logger.error("Can't find topMost, body = \(body)")
                completion?(nil, RouteError.fromNotFound)
                return
            }
            guard let vc = self.viewController(for: body) else {
                completion?(nil, RouteError.resourceNotFound)
                return
            }
            self._push(vc, from: fromVC, animated: animated, file: file, function: function, line: line, completion: completion)
        }
    }

    func push(_ vc: UIViewController, from: UIViewController? = nil, animated: Bool = true,
              file: String = #fileID, function: String = #function, line: Int = #line,
              completion: ((UIViewController?, Error?) -> Void)? = nil) {
        Util.runInMainThread { [weak self] in
            guard let self = self, let fromVC = self.calculateFrom(context: from) else {
                self?.logger.error("Can't find topMost, vc = \(vc)")
                completion?(nil, RouteError.fromNotFound)
                return
            }
            self._push(vc, from: fromVC, animated: animated, file: file, function: function, line: line, completion: completion)
        }
    }

    func present<T: RouteBody> (body: T, wrap: UINavigationController.Type? = nil, from: UIViewController? = nil,
                                file: String = #fileID, function: String = #function, line: Int = #line,
                                animated: Bool = true, completion: ((UIViewController?, Error?) -> Void)? = nil) {
        Util.runInMainThread { [weak self] in
            guard let self = self, let fromVC = self.calculateFrom(context: from) else {
                self?.logger.error("Can't find topMost, body = \(body)")
                completion?(nil, RouteError.fromNotFound)
                return
            }
            guard let controller = self.viewController(for: body) else {
                completion?(nil, RouteError.resourceNotFound)
                return
            }
            self._present(controller, from: fromVC, wrap: wrap, animated: animated, file: file, function: function, line: line) {
                completion?(controller, nil)
            }
        }
    }

    func present(_ vc: UIViewController, wrap: UINavigationController.Type? = nil,
                 from: UIViewController? = nil, animated: Bool = true,
                 file: String = #fileID, function: String = #function, line: Int = #line,
                 completion: ((UIViewController?, Error?) -> Void)? = nil) {
        Util.runInMainThread { [weak self] in
            guard let self = self, let fromVC = self.calculateFrom(context: from) else {
                self?.logger.error("Can't find topMost, viewController = \(vc)")
                completion?(nil, RouteError.fromNotFound)
                return
            }
            self._present(vc, from: fromVC, wrap: wrap, animated: animated, file: file, function: function, line: line) { [weak vc] in
                completion?(vc, nil)
            }
        }
    }

    func presentDynamicModal(_ vc: UIViewController, regularConfig: DynamicModalConfig, compactConfig: DynamicModalConfig,
                             from: UIViewController? = nil, file: String = #fileID, function: String = #function, line: Int = #line,
                             animated: Bool = true, completion: ((UIViewController?, Error?) -> Void)? = nil) {
        Util.runInMainThread { [weak self] in
            guard let self = self, let fromVC = self.calculateFrom(context: from) else {
                self?.logger.error("Can't find topMost, when present DynamicModal viewController = \(vc)")
                completion?(nil, RouteError.fromNotFound)
                return
            }
            self.logger.info("presentDynamicModal \(vc)", file: file, function: function, line: line)
            MemoryLeakTracker.addAssociatedItem(vc, name: vc.description, for: self.sessionId)
            fromVC.presentDynamicModal(vc, regularConfig: regularConfig, compactConfig: compactConfig, animated: animated) { [weak vc] _ in
                completion?(vc, nil)
            }
        }
    }

    func presentDynamicModal(_ vc: UIViewController, config: DynamicModalConfig,
                             from: UIViewController? = nil, file: String = #fileID, function: String = #function, line: Int = #line,
                             animated: Bool = true, completion: ((UIViewController?, Error?) -> Void)? = nil) {
        Util.runInMainThread { [weak self] in
            guard let self = self, let fromVC = self.calculateFrom(context: from) else {
                self?.logger.error("Can't find topMost, when present DynamicModal viewController = \(vc)")
                completion?(nil, RouteError.fromNotFound)
                return
            }
            self.logger.info("presentDynamicModal \(vc)", file: file, function: function, line: line)
            MemoryLeakTracker.addAssociatedItem(vc, name: vc.description, for: self.sessionId)
            fromVC.presentDynamicModal(vc, config: config, animated: animated) { [weak vc] _ in
                completion?(vc, nil)
            }
        }
    }

    private func _push(_ vc: UIViewController, from: UIViewController, animated: Bool,
                       file: String = #fileID, function: String = #function, line: Int = #line,
                       completion: ((UIViewController?, Error?) -> Void)?) {
        guard let nav = (from as? UINavigationController) ?? from.navigationController else {
            self.logger.error("Can't find navigationController, from = \(from), vc = \(vc)")
            completion?(nil, RouteError.navigationNotFound)
            return
        }
        self.logger.info("push \(vc)", file: file, function: function, line: line)
        MemoryLeakTracker.addAssociatedItem(vc, name: vc.description, for: self.sessionId)
        nav.pushViewController(vc, animated: animated)
        if let coordinator = nav.transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { [weak vc] (_) in
                completion?(vc, nil)
            }
        } else {
            completion?(vc, nil)
        }
    }

    private func _present(_ vc: UIViewController, from: UIViewController, wrap: UINavigationController.Type?, animated: Bool,
                          file: String = #fileID, function: String = #function, line: Int = #line,
                          completion: (() -> Void)? = nil) {
        self.logger.info("present \(vc), wrap = \(wrap)", file: file, function: function, line: line)
        var controller = vc
        if let wrap = wrap, !(controller is UINavigationController) {
            controller = wrap.init(rootViewController: controller)
        }
        MemoryLeakTracker.addAssociatedItem(vc, name: vc.description, for: self.sessionId)
        from.vc.safePresent(controller, animated: animated, completion: completion)
    }
}

extension Router: ShortcutHandler {
    func canHandleShortcutAction(context: ShortcutActionContext) -> Bool {
        if context.action.id == .vc.floatWindow, let session = self.session, !session.isPending {
            return context.isValid(for: session)
        }
        return false
    }

    func handleShortcutAction(context: ShortcutActionContext, completion: @escaping (Result<Any, Error>) -> Void) {
        let isFloating = context.bool("isFloating", defaultValue: true)
        guard let w = self.window, w.isFloating != isFloating, let session = self.session else {
            logger.info("setWindowFloating ignored, current is \(self.window?.isFloating)")
            completion(.success(true))
            return
        }
        let reason = context.fromSource
        if isFloating, context.bool("leaveWhenUnfloatable"), let root = w.rootViewController, !(root is FloatableViewController) {
            logger.info("leave session from lark(\(reason))")
            session.leave(.forceExit) { _ in
                completion(.success(true))
            }
        } else {
            logger.info("setWindowFloating from lark(\(reason)), isFloating = \(isFloating)")
            Util.runInMainThread {
                w.setFloating(isFloating, reason: reason) {
                    completion(.success($0))
                }
            }
        }
    }
}

extension Router: FloatingWindowDelegate {
    func didChangeFloating(_ isFloating: Bool, window: FloatingWindow, isAnimationCompleted: Bool) {
        if isAnimationCompleted {
            listeners.forEach { $0.didChangeWindowFloatingAfterAnimation(isFloating, window: window) }
            self.session?.service?.postMeetingChanges({ $0.windowInfo.update(window) })
        } else {
            listeners.forEach { $0.didChangeWindowFloatingBeforeAnimation(isFloating, window: window) }
        }
    }
}

extension Router {
    var topMost: UIViewController? {
        window?.rootViewController?.vc.topMost
    }

    private func calculateFrom(context: UIViewController?) -> UIViewController? {
        if let context = context {
            return context
        } else {
            return topMost
        }
    }

    func dismissTopMost(animated: Bool = true, completion: (() -> Void)? = nil) {
        Util.runInMainThread {
            if let presenter = self.topMost?.presentingViewController {
                presenter.dismiss(animated: animated, completion: completion)
            } else {
                //  debug模式 iPad点击cc会触发，但是不影响功能，暂时注释掉
                //  assertionFailure("Can't dismiss current view controller")
                self.logger.error("Can't dismiss current view controller")
                completion?()
            }
        }
    }
}

// MARK: - Window
extension Router {
    var isFloating: Bool {
        return window?.isFloating ?? false
    }

    var isFloatTransitioning: Bool {
        return window?.isFloatTransitioning ?? false
    }

    func setWindowFloating(_ isFloating: Bool, animated: Bool = true,
                           file: String = #fileID, function: String = #function, line: Int = #line,
                           completion: ((Bool) -> Void)? = nil) {
        self.logger.info("setWindowFloating: \(isFloating)", file: file, function: function, line: line)
        Util.runInMainThread {
            if let w = self.window {
                w.setFloating(isFloating, reason: function, animated: animated, completion: completion)
            } else {
                completion?(true)
            }
        }
    }

    func startRoot<T: RouteBody>(_ body: T, animated: Bool = true,
                                 dynamicModalConfigs: [DynamicModalConfig] = [],
                                 file: String = #fileID, function: String = #function, line: Int = #line,
                                 completion: ((UIViewController?, Error?) -> Void)? = nil) {
        Util.runInMainThread {
            guard let bodyVC = self.viewController(for: body) else {
                completion?(nil, RouteError.resourceNotFound)
                return
            }
            let useDynamicModal = !dynamicModalConfigs.isEmpty
            self.logger.info("startRoot \(type(of: body)), useDynamicModal:\(useDynamicModal), animated = \(animated), isWindowNil = \(self.window == nil)",
                             file: file, function: function, line: line)
            let root = useDynamicModal ? ZombieViewController() : bodyVC
            let window: FloatingWindow
            let isNewWindow: Bool = self.window == nil
            if let w = self.window {
                window = w
            } else {
                window = self._createWindow()
            }
            window.replaceRootViewController(root)
            let wrapper: (Bool) -> Void = { [weak self] _ in
                if useDynamicModal {
                    if dynamicModalConfigs.count > 1 {
                        self?.presentDynamicModal(bodyVC, regularConfig: dynamicModalConfigs[0], compactConfig: dynamicModalConfigs[1],
                                                  from: root, animated: animated, completion: completion)
                    } else {
                        self?.presentDynamicModal(bodyVC, config: dynamicModalConfigs[0],
                                                 from: root, animated: animated, completion: completion)
                    }
                } else {
                    completion?(bodyVC, nil)
                }
            }
            if isNewWindow {
                // formSheet为true时 弹出动画不要window
                window.present(animated: animated && !useDynamicModal, completion: wrapper)
            } else {
                wrapper(true)
            }
        }
    }

    func dismissWindow(animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        Util.runInMainThread {
            self._dismissWindow(window: self.window, animated: animated, completion: completion)
        }
    }

    private func _createWindow() -> FloatingWindow {
        _ = VcSceneGlobalListener.shared
        let window = VCScene.createWindow(FloatingWindow.self, tag: .floating)
        window.setup(sessionId: sessionId, dependency: larkUtil.window, setting: setting)
        // 为新的 window 设置水印
        window.setupWatermark(provider: larkUtil)
        self.window?.delegate = nil
        self.window = window
        self.pipActiveView.removeFromSuperview()
        self.window?.addSubview(self.pipActiveView)
        VCScene.setWindow(window)
        window.delegate = self
        listeners.forEach { $0.didChangeWindow(window) }
        session?.service?.postMeetingChanges({ $0.windowInfo.update(window) })
        return window
    }

    private func _dismissWindow(window: FloatingWindow?, animated: Bool, completion: ((Bool) -> Void)?) {
        let listeners = self.listeners
        let security = self.larkUtil.security
        Util.runInMainThread { [weak self] in
            ByteViewDialogManager.shared.triggerAutoDismiss()
            SecurityComplianceManager.shared.cleanSecurityAlertTime()
            let wrapper: ((Bool) -> Void) = { [weak self] flag in
                self?.closeSideBarScenesIfNeeded()
                completion?(flag)
            }
            /// openScreenProtection
            security.vcScreenCastChange(false)
            if let w = window {
                window?.delegate = nil
                self?.window = nil
                VCScene.releaseWindow(w)
                listeners.forEach { $0.didChangeWindow(nil) }
                self?.session?.service?.postMeetingChanges({ $0.windowInfo.update(nil) })
                if VCScene.isAuxSceneOpen {
                    w.dismiss(animated: false, completion: nil)
                    VCScene.closeAuxSceneOnDismiss()
                    wrapper(true)
                } else {
                    w.dismiss(animated: animated, completion: wrapper)
                }
            } else {
                VCScene.closeAuxSceneOnDismiss()
                wrapper(true)
            }
        }
    }

    var isPageSheetPresenting: Bool {
        guard let window = self.window, let transform = window.rootViewController?.view.superview?.layer.transform else {
            return false
        }
        return !CATransform3DIsIdentity(transform)
    }
}

extension RouterListener {
    func didChangeWindow(_ window: FloatingWindow?) {}
    func didChangeWindowFloatingBeforeAnimation(_ isFloating: Bool, window: FloatingWindow?) {}
    func didChangeWindowFloatingAfterAnimation(_ isFloating: Bool, window: FloatingWindow?) {}
}

import ByteViewSetting
private class VcSceneGlobalListener {
    static let shared = VcSceneGlobalListener()
    init() {
        if #available(iOS 13, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(didChangeVcScene(_:)), name: VCScene.didChangeVcSceneNotification, object: nil)
        }
    }

    @objc private func didChangeVcScene(_ notification: Notification) {
        if #available(iOS 13, *), let window = notification.object as? FloatingWindow, let scene = window.windowScene,
           let oldScene = notification.userInfo?[VCScene.previousSceneKey] as? UIWindowScene {
            if oldScene.isVcAuxScene {
                MeetingTracks.trackAllCloseAuxWindow()
            }
            if scene.isVcAuxScene, window.isFloating {
                window.setFloating(false, reason: "open_aux_scene", animated: false, completion: nil)
            } else {
                Logger.window.info("setWindowFloating: \(!VCScene.isAuxSceneOpen)")
                window.setFloating(!VCScene.isAuxSceneOpen, reason: #function, animated: false, completion: nil)
            }
            if !window.sessionId.isEmpty {
                MeetingObserverCenter.shared.postChanges(for: window.sessionId, action: { $0.windowInfo.update(window) })
            }
        }
    }
}

private extension VCScene {
    static func closeAuxSceneOnDismiss() {
        closeAuxSceneIfNeeded(shouldClose: {
            if !MeetingManager.shared.hasActiveMeeting {
                /// 只有没有会议时可以关闭
                return true
            }
            if let session = MeetingManager.shared.currentSession, session.state == .ringing, !session.isAcceptRinging {
                /// 响铃页不支持独立scene，仅接受响铃而转的忙线ringing不关闭独立窗口
                return true
            }
            return false
        })
    }
}

extension Router {

    enum SceneOpenAction {
        /// 无操作
        case none
        /// vc window 小窗
        case floatingVC
        /// 打开
        case open
        /// 重打开/激活
        case reopen
        /// 关闭
        case close
    }

    /// 已经打开的 UIScene 是否可以再次调用激活（不可作为台前调度判断）。
    /// 现在的场景是：
    /// 分屏模式下，已经打开的活跃 UIScene 第二次点击需要关闭；
    /// 台前调度模式下，已经打开的活跃 UIScene 第二次点击无需关闭；
    var connectedSceneActivatable: Bool {
        guard #available(iOS 16.0, *), !VCScene.splitIsAllSelf else {
            return false
        }

        var activeScenesCount = 0
        let scenes = UIApplication.shared.connectedScenes
        for scene in scenes {
            guard scene.activationState == .foregroundActive else {
                continue
            }
            activeScenesCount += 1
        }

        return activeScenesCount >= 2
    }

    /// 按照 VC 业务要求展示 UIScene。
    /// 分屏模式：当前 scene 不存在或非 foregroundActive 状态 -> 打开，foregroundActive -> 关闭（可配置不关闭）；
    /// 台前调度：当前 scene 不存在 -> 打开，非 foregroundActive 状态 -> 切换到前台；
    /// - Parameters:
    ///   - sceneInfo: SceneInfo
    ///   - localContext: localContext，sideBar 类型的需传入待展示的 ViewController
    ///   - keepOpenForActivated: true：foregroundActive 状态下保持打开，false：关闭
    ///   - actionCallback: 执行类型，参考 OpenAction
    ///   - completion: completion（关闭或重开 scene 不报错无回调）
    @available(iOS 13.0, *)
    func openByteViewScene(sceneInfo: SceneInfo,
                           localContext: AnyObject? = nil,
                           keepOpenForActivated: Bool = false,
                           actionCallback: ((SceneOpenAction) -> Void)? = nil,
                           completion: ((UIWindow?, Error?) -> Void)? = nil)
    {
        if let scene = VCScene.connectedScene(scene: sceneInfo), scene.activationState == .foregroundActive {
            var vcWindowFullInScene = false
            if let ws = self.window?.windowScene, ws.session == scene.session, !self.isFloating {
                vcWindowFullInScene = true
            }
            if self.connectedSceneActivatable, !vcWindowFullInScene {
                actionCallback?(.reopen)
                VCScene.reopenScene(scene) { err in
                    completion?(nil, err)
                }
            } else if vcWindowFullInScene {
                actionCallback?(.floatingVC)
                self.setWindowFloating(true)
            } else if !keepOpenForActivated {
                actionCallback?(.close)
                VCScene.closeScene(sceneInfo) { err in
                    completion?(nil, err)
                }
            } else {
                actionCallback?(.none)
            }
        } else {
            actionCallback?(.open)
            let wrapper: ((UIWindow?, Error?) -> Void) = { [weak self] (window, error) in
                if let window = window {
                    self?.sideBarScenes.add(window)
                }
                completion?(window, error)
            }
            VCScene.openScene(info: sceneInfo, localContext: localContext, completion: wrapper)
        }
    }

    /// 关闭所有通过 openByteViewScene() 方法创建的 Scene
    func closeSideBarScenesIfNeeded() {
        guard #available(iOS 13, *) else { return }
        self.sideBarScenes.allObjects.forEach { window in
            if let scene = window.windowScene {
                VCScene.deactive(from: scene)
            }
        }
    }
}
