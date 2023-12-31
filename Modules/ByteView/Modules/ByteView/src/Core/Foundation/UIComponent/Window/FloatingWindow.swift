//
//  FloatingWindow.swift
//  ByteView
//
//  Created by kiri on 2020/7/12.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewCommon
import ByteViewTracker
import ByteViewUI
import ByteViewMeeting
import ByteViewSetting

protocol FloatableViewController {
}

/// only called when isFloating changed
protocol FloatingWindowTransitioning {
    func floatingWindowWillChange(to isFloating: Bool)
    func floatingWindowDidChange(to isFloating: Bool)
    func floatingWindowWillTransition(to frame: CGRect, isFloating: Bool)
    func animateAlongsideFloatingWindowTransition(to frame: CGRect, isFloating: Bool)
    func floatingWindowDidTransition(to frame: CGRect, isFloating: Bool)
}

extension FloatingWindowTransitioning {
    func floatingWindowWillChange(to isFloating: Bool) { }
    func floatingWindowDidChange(to isFloating: Bool) { }
    func floatingWindowWillTransition(to frame: CGRect, isFloating: Bool) { }
    func animateAlongsideFloatingWindowTransition(to frame: CGRect, isFloating: Bool) { }
    func floatingWindowDidTransition(to frame: CGRect, isFloating: Bool) { }
}

protocol FloatingWindowDelegate: AnyObject {
    func didChangeFloating(_ isFloating: Bool, window: FloatingWindow, isAnimationCompleted: Bool)
}

final class FloatingWindow: UIWindow {
    private var logger = Logger.window
    private(set) var sessionId: String = ""
    private var floatingAnimator: FloatingWindowAnimator = DefaultFloatingWindowAnimator(logger: Logger.window)
    private var dependency: WindowDependency?
    private var isExternalWindowEnabled: Bool { dependency?.isExternalWindowEnabled ?? false }

    // MARK: - public properties
    /// 是否浮动
    private(set) var isFloating: Bool = false

    /// 是否正在做浮动/全屏切换动画
    private(set) var isFloatTransitioning = false

    /// 仅供Router使用
    weak var delegate: FloatingWindowDelegate?

    // MARK: - private properties
    /// 上一个KeyWindow
    private weak var _previousKeyWindow: UIWindow?
    private(set) var previousKeyWindow: UIWindow? {
        get {
            if let pw = _previousKeyWindow, !pw.isHidden {
                if #available(iOS 13.0, *) {
                    if pw.windowScene == self.windowScene {
                        return pw
                    } else {
                        return nil
                    }
                } else {
                    return pw
                }
            } else {
                return nil
            }
        } set {
            _previousKeyWindow = newValue
        }
    }

    // 可移动时暂存的上一个点
    private var lastLocation: CGPoint = .zero
    private var isFloatChangedWhenTransitioning = false

    // 真实可移动的区域
    private var movableRegion: CGRect = .zero

    private var floatValidRegion: CGRect {
        floatingAnimator.floatingRegion(for: self)
    }

    private lazy var pan: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handPan(_:)))
    private var isAvailable = false

    /// 能否转移scene
    private var changeSceneEnabled: Bool = VCScene.supportsMultipleScenes

    deinit {
        logger.info("deinit FloatingWindow")
        NotificationCenter.default.removeObserver(self)
    }

    func setup(sessionId: String, dependency: WindowDependency, setting: MeetingSettingManager?) {
        self.sessionId = sessionId
        self.logger = Logger.window.withContext(sessionId).withTag("[FloatingWindow(\(sessionId))][\(address(of: self))]")
        if let animator = VCFloatingWindowAnimator(logger: logger, dependency: dependency, setting: setting) {
            self.floatingAnimator = animator
            self.dependency = dependency
        } else {
            self.floatingAnimator = DefaultFloatingWindowAnimator(logger: logger)
        }

        logger.info("init FloatingWindow, isExternalWindowEnabled = \(isExternalWindowEnabled)")
        // ipad pro 11寸 在没有其他地方更改的情况下这个值居然是 true
        clipsToBounds = false
        NotificationCenter.default.addObserver(self, selector: #selector(statusBarDidChangeOrientation(_:)),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
        if Display.pad {
            self.vc.windowSceneLayoutContextObservable.addObserver(self) { [weak self] _, _ in
                guard let `self` = self else { return }
                if self.isFloating {
                    // crash: floatingWindowWillTransition will change ApplicationSceneUpdateObservable.observerMap
                    DispatchQueue.main.async {
                        self.updateLayout(animated: false, completion: nil)
                    }
                }
            }
        }

        pan.isEnabled = false
        addGestureRecognizer(pan)
        if #available(iOS 13, *), Display.pad {
            setupSceneListeners()
        }
    }

    func replaceRootViewController(_ root: UIViewController) {
        if let vc = self.rootViewController, vc.presentedViewController != nil {
            vc.dismiss(animated: false) { [weak self] in
                self?._replaceRootViewController(root)
            }
        } else {
            _replaceRootViewController(root)
        }
    }

    private func _replaceRootViewController(_ root: UIViewController) {
        if !(root is FloatableViewController) && self.isFloating {
            self.logger.info("root is not floatable, setFloating to false")
            self.setFloating(false, reason: "not_floatable", animated: false)
            self.rootViewController = root
            self.bringWatermarkToFront()
        } else if let dep = self.dependency, dep.isExternalWindowEnabled, self.isFloating, !self.isFloatTransitioning {
            dep.replaceViewController(with: root)
        } else {
            self.rootViewController = root
            self.bringWatermarkToFront()
        }
        root.view.clipsToBounds = true
        root.view.layer.cornerRadius = self.layer.cornerRadius
    }

    /// 上一次改变状态的时间（present/floating/dismiss)，用来计时
    private var lastStateTime = CACurrentMediaTime()
    /// 重置状态时间，并返回当前耗时
    @discardableResult
    private func getStateElapseAndReset() -> Int {
        let duration = Int(CACurrentMediaTime() - lastStateTime)
        lastStateTime = CACurrentMediaTime()
        return duration
    }

    var isIgnoringSetFloatingActions = false
    // MARK: - switch floating
    func setFloating(_ isFloating: Bool, reason: String, animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        if isIgnoringSetFloatingActions {
            logger.info("change floating to \(isFloating) ignored, window = \(self), reason = \(reason), isIgnoringSetFloatingActions = true")
            completion?(false)
            return
        }
        let appState = UIApplication.shared.applicationState
        guard isAvailable, self.isFloating != isFloating else {
            logger.info("change floating to \(isFloating) invalid, window = \(self), reason = \(reason), app state = \(appState.rawValue)")
            completion?(false)
            return
        }
        if #available(iOS 13, *), isFloating, VCScene.isAuxSceneOpen {
            // 独立窗口不支持浮窗
            logger.info("vc is in auxiliary mode, setFloating ignored")
            completion?(true)
            return
        }
        if isFloating, let root = self.rootViewController, !(root is FloatableViewController) {
            logger.error("change floating to \(isFloating) failed, root is not floatable")
            completion?(false)
            return
        }
        if let vc = self.rootViewController, vc.presentedViewController != nil {
            vc.dismiss(animated: false) { [weak self] in
                if let self = self {
                    self._setFloating(isFloating, reason: reason, animated: animated, appState: appState, completion: completion)
                } else {
                    completion?(true)
                }
            }
            return
        }
        self._setFloating(isFloating, reason: reason, animated: animated, appState: appState, completion: completion)
    }

    private func _setFloating(_ isFloating: Bool, reason: String, animated: Bool, appState: UIApplication.State, completion: ((Bool) -> Void)?) {
        logger.info("change floating to \(isFloating), window = \(self), reason = \(reason), app state = \(appState.rawValue)")
        self.isFloating = isFloating
        let elapse = getStateElapseAndReset()
        DevTracker.post(.criticalPath(isFloating ? .enter_window_floating : .enter_window_fullscreen).category(.window)
            .params([.env_id: sessionId, .elapse: elapse, .reason: reason, "is_suspend": isExternalWindowEnabled]))
        isFloatChangedWhenTransitioning = true
        // 原位置
        delegate?.didChangeFloating(isFloating, window: self, isAnimationCompleted: false)
        let isFloatChanged = self.isFloatChangedWhenTransitioning
        let transitioningObject = isFloatChanged ? self.rootViewController as? FloatingWindowTransitioning : nil
        transitioningObject?.floatingWindowWillChange(to: isFloating)

        updateLayout(animated: animated) { succ in
            completion?(succ)
            self.updateFloatStyle()
        }
        if !self.isFloating { // 小窗到全屏才执行
            updateMenuVCWindowLevelIfNeeded()
        }
        // 新位置
        delegate?.didChangeFloating(isFloating, window: self, isAnimationCompleted: true)
    }

    /// 拉高MenuVC使用的window层级
    private func updateMenuVCWindowLevelIfNeeded() {
        if #available(iOS 16.0, *) {
            let menuWindow: UIWindow?
            if let scene = self.windowScene {
                menuWindow = scene.windows.first { (w) -> Bool in
                    String(describing: type(of: w)) == "UITextEffectsWindow"
                }
            } else {
                menuWindow = UIApplication.shared.windows.first { (w) -> Bool in
                    String(describing: type(of: w)) == "UITextEffectsWindow"
                }
            }

            let target = self
            guard let w = menuWindow, w != target else {
                Logger.ui.warn("menuWindow or self is invalid, increase menuWindow.level operation ignored")
                return
            }
            guard w.windowLevel <= target.windowLevel else {
                Logger.ui.debug("menuWindow.windowLevel is higher, increase menuWindow.level operation ignored")
                return
            }
            let newMenuWindowLevel = target.windowLevel + 1
            Logger.ui.info("menuWindow.windowLevel increase to \(newMenuWindowLevel)")
            w.windowLevel = newMenuWindowLevel
        }
    }

    // MARK: - event handlers
    // ipad在分屏操作后 有时候坐标系没有及时更新，屏幕外的点击也能响应,所以重写该方法自行进行计算
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if Display.pad {
            // 转换坐标系到主屏幕
            let convertPoint = convert(point, to: nil)
            return frame.contains(convertPoint)
        } else {
            return super.point(inside: point, with: event)
        }
    }

    func resetMovableReginIfNeeded(function: String = #function) {
        if isAvailable, isFloating {
            movableRegion = floatValidRegion
            recoverSizeIfNeeded(animated: false)
            logger.info("reset movableRegion, \(movableRegion), from \(function)")
        }
    }

    @objc private func statusBarDidChangeOrientation(_ sender: Any?) {
        resetMovableReginIfNeeded()
    }

    @objc private func applicationDidBecomeActive(_ sender: Any?) {
        resetMovableReginIfNeeded()
    }

    @objc private func handPan(_ pan: UIPanGestureRecognizer) {
        let location = pan.location(in: pan.view)
        switch pan.state {
        case .began:
            lastLocation = location
        case .changed:
            let dx = location.x - lastLocation.x
            let dy = location.y - lastLocation.y
            var newFrame = self.frame
            newFrame.origin.x += dx
            newFrame.origin.y += dy
            self.frame = newFrame
        case .ended, .cancelled, .failed:
            recoverSizeIfNeeded()
        default:
            break
        }
    }

    // MARK: - layout
    func updateLayout(animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        if !isAvailable {
            completion?(false)
            return
        }
        let isFloatChanged = self.isFloatChangedWhenTransitioning
        self.isFloatChangedWhenTransitioning = false
        let isFloating = self.isFloating
        Util.dismissKeyboard()
        if isFloating {
            self.previousKeyWindow?.makeKeyAndVisible()
            movableRegion = floatValidRegion
        } else {
            self.makeKeyAndVisible()
        }
        pan.isEnabled = isFloating
        let newFrame = floatingAnimator.animationEndFrame(for: self)
        isFloatTransitioning = true
        floatingAnimator.prepareAnimation(for: self, to: newFrame)
        let transitioningObject = isFloatChanged ? self.rootViewController as? FloatingWindowTransitioning : nil
        transitioningObject?.floatingWindowWillTransition(to: newFrame, isFloating: isFloating)
        layoutIfNeeded()
        AppreciableTracker.shared.start(.vc_floating_switch_time)
        UIApplication.shared.beginIgnoringInteractionEvents()
        floatingAnimator.animate(for: self, animated: animated, to: newFrame, alongsideAnimation: {
            if #available(iOS 16.0, *), Display.phone {
                self.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            }
            if isFloating {
                //不需要额外加动画，否则外面的lark页面容易出现布局问题
                // 代码位置必须在这里，时机太早回到Lark后，VCWindow的方向会被记录
                UIDevice.updateDeviceOrientationForViewScene(nil, to: .portrait, animated: false)
                self.floatingAnimator.updateSupportedInterfaceOrientations()
            }
            self.logger.info("floating window is key window: \(self.isKeyWindow), window = \(self)")
            transitioningObject?.animateAlongsideFloatingWindowTransition(to: newFrame, isFloating: isFloating)
        }, completion: { isFinished in
            UIApplication.shared.endIgnoringInteractionEvents()
            AppreciableTracker.shared.end(.vc_floating_switch_time, params: ["isFloating": isFloating])
            transitioningObject?.floatingWindowDidTransition(to: self.frame, isFloating: isFloating)
            self.isFloatTransitioning = false
            self.logger.info("change floating finished: \(self.isFloating), window = \(self)")
            completion?(isFinished)
            transitioningObject?.floatingWindowDidChange(to: isFloating)
            if #available(iOS 16.0, *), Display.phone, isFloating {
                UIApplication.shared.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            }
        })
    }

    private func recoverSizeIfNeeded(animated: Bool = true) {
        if !isAvailable { return }
        let originFrame = self.frame
        var newFrame = originFrame
        if newFrame.midX > movableRegion.midX {
            newFrame.origin.x = movableRegion.maxX - newFrame.width
        } else {
            newFrame.origin.x = movableRegion.minX
        }

        if newFrame.minY < movableRegion.minY {
            newFrame.origin.y = movableRegion.minY
        } else if newFrame.maxY > movableRegion.maxY {
            newFrame.origin.y = movableRegion.maxY - newFrame.height
        }

        guard newFrame != originFrame else {
            return
        }
        if animated {
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0,
                           options: [], animations: { [weak self] in self?.frame = newFrame })
        } else {
            self.frame = newFrame
        }
    }

    // MARK: - present & dismiss
    func present(animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        logger.info("present FloatingWindow, animated = \(animated), \(self.description)")
        getStateElapseAndReset()
        DevTracker.post(.criticalPath(.present_floating_window).category(.window).params([.env_id: sessionId]))
        isAvailable = true
        let completionWrapper: (Bool) -> Void = { b in
            UIApplication.shared.endIgnoringInteractionEvents()
            completion?(b)
        }

        // 移除外部第一响应者，保证键盘消失
        Util.dismissKeyboard()

        if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }), keyWindow != self {
            self.previousKeyWindow = keyWindow
        }
        // NOTE: 注意不要设置clipsToBounds=true，因为Window存在阴影
        // iOS 13 以下 windowLevel 过高会遮挡状态栏
        self.windowLevel = .floatingWindow
        self.backgroundColor = UIColor.clear
        self.makeKeyAndVisible()
        // 兜底，bringWatermarkToFront在makeKeyAndVisible之前执行可能无效
        self.bringWatermarkToFront()
        UIApplication.shared.beginIgnoringInteractionEvents()
        if animated {
            let animation: () -> Void = {
                self.frame.origin.y = 0
            }
            frame.origin.y = bounds.size.height
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0,
                           options: [], animations: animation, completion: completionWrapper)
        } else {
            completionWrapper(true)
        }
        updateMenuVCWindowLevelIfNeeded()
    }

    func dismiss(animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        guard isAvailable else {
            completion?(false)
            return
        }
        logger.info("dismiss FloatingWindow, animated = \(animated)")
        let elapse = getStateElapseAndReset()
        DevTracker.post(.criticalPath(.dismiss_floating_window).category(.window).params([.env_id: sessionId, .elapse: elapse]))
        isAvailable = false
        let animation: () -> Void = {
            self.frame.origin.y = self.bounds.size.height
        }

        let completionWrapper: (Bool) -> Void = { b in
            let previousKeyWindow = self.previousKeyWindow
            previousKeyWindow?.rootViewController?.view.setNeedsLayout()
            // previousKeyWindow?.rootViewController?.view.layoutIfNeeded()
            if self.rootViewController?.presentedViewController != nil {
                self.rootViewController?.dismiss(animated: false, completion: nil)
            }
            self.isHidden = true
            self.rootViewController = nil
            self.floatingAnimator = DefaultFloatingWindowAnimator(logger: self.logger)
            UIApplication.shared.endIgnoringInteractionEvents()
            previousKeyWindow?.makeKeyAndVisible()
            completion?(b)
            self.logger.info("dismiss FloatingWindow finished")
        }

        UIApplication.shared.beginIgnoringInteractionEvents()

        if !isFloating && animated {
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.44, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0,
                           options: [], animations: animation, completion: completionWrapper)
        } else {
            animation()
            completionWrapper(true)
        }

        MemoryLeakTracker.addAssociatedItem(self, name: "FloatingWindow", for: sessionId)
    }

    static var activeWindows: [UIWindow] {
        let windows = UIApplication.shared.windows
        if #available(iOS 13.0, *) {
            return windows.filter { !$0.isHidden && $0.windowScene?.activationState == .some(.foregroundActive) }
        } else {
            return windows.filter { !$0.isHidden }
        }
    }

    var isLandscapeMode: Bool {
        if #available(iOS 13.0, *) {
            if let scene = self.windowScene {
                return scene.interfaceOrientation.isLandscape
            } else if let scene = UIApplication.shared.connectedScenes.first(where: { (scene) -> Bool in
                return scene.activationState == .foregroundActive && scene.session.role == .windowApplication
            }) as? UIWindowScene {
                // 尽量给一个相对正确的值
                return scene.interfaceOrientation.isLandscape
            }
            return Display.pad ? true : false
        } else {
            return UIApplication.shared.statusBarOrientation.isLandscape
        }
    }
}

@available(iOS 13.0, *)
extension FloatingWindow {
    static let didFailToActiveVcSceneNotification = Notification.Name(rawValue: "vc.scene.didFailToActiveVcScene")

    private func setupSceneListeners() {
        logWindowScene("setupSceneListeners")
        trackWindowScene()
        NotificationCenter.default.addObserver(self, selector: #selector(sceneWillDeactivate(_:)),
                                               name: UIScene.willDeactivateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneWillEnterForeground(_:)),
                                               name: UIScene.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneDidEnterBackground(_:)),
                                               name: UIScene.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneDidDisconnect(_:)),
                                               name: UIScene.didDisconnectNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sceneDidActive(_:)),
                                               name: UIScene.didActivateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pipStatusDidChange(_:)),
                                               name: PIPManager.didChangePiPStatusNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeVcScene(_:)),
                                               name: VCScene.didChangeVcSceneNotification, object: nil)
    }

    @objc private func sceneWillDeactivate(_ notification: Notification) {
        logSceneNotification(notification)
    }

    @objc private func sceneWillEnterForeground(_ notification: Notification) {
        logSceneNotification(notification)
    }

    @objc private func sceneDidActive(_ notification: Notification) {
        logSceneNotification(notification)
        // nolint-next-line: magic number
        logger.info("changeSceneIfNeeded on active, \(self.windowScene?.activationState.rawValue ?? -1000)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.changeSceneIfNeeded()
        }
    }

    @objc private func sceneDidEnterBackground(_ notification: Notification) {
        logSceneNotification(notification)
        // nolint-next-line: magic number
        logger.info("changeSceneIfNeeded on background, \(self.windowScene?.activationState.rawValue ?? -1000)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.changeSceneIfNeeded()
        }
    }

    @objc private func didChangeVcScene(_ notification: Notification) {
        if let window = notification.object as? FloatingWindow, window == self {
            logWindowScene(notification.name.rawValue)
            trackWindowScene()
        }
    }

    @objc private func pipStatusDidChange(_ notification: Notification) {
        guard isAvailable, let isPiPActive = notification.userInfo?[PIPManager.pipStatusKey] as? Bool else {
            return
        }
        changeSceneEnabled = VCScene.supportsMultipleScenes && !isPiPActive
        isHidden = self.isFloating && isPiPActive
    }

    /// 杀死多scene
    @objc private func sceneDidDisconnect(_ notification: Notification) {
        logSceneNotification(notification)
        guard let scene = notification.object as? UIWindowScene, scene == self.windowScene else {
            return
        }
        changeWindowScene(isDisconnected: true)
    }

    private func logSceneNotification(_ notification: Notification, file: String = #fileID, function: String = #function, line: Int = #line) {
        if let scene = notification.object as? UIWindowScene, scene == self.windowScene {
            logWindowScene(notification.name.rawValue)
        }
    }

    private func logWindowScene(_ event: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        guard let ws = self.windowScene else { return }
        logger.info("FloatingWindowScene: \(event), \(ws.debugDescription)", file: file, function: function, line: line)
    }

    private func trackWindowScene() {
        guard let ws = self.windowScene else { return }
        DevTracker.post(.criticalPath(.change_window_scene).category(.window).params([.env_id: sessionId, .target: ws.session.persistentIdentifier, "is_aux": ws.isVcAuxScene, .content: ws.debugDescription]))
    }

    private func changeSceneIfNeeded() {
        guard let scene = self.windowScene else { return }
        let isLoadFinished = VCScene.isSceneTransitionFinished
        let currentState = scene.activationState
        logger.info("changeSceneIfNeeded, isLoadFinished = \(isLoadFinished), state = \(currentState.rawValue)")
        if isLoadFinished, currentState == .background {
            changeWindowScene()
        }
    }

    private func changeWindowScene(isDisconnected: Bool = false) {
        if !isAvailable { return }
        if UIApplication.shared.connectedScenes.isEmpty {
            logger.error("connectedScenes isEmpty, openSessions = \(UIApplication.shared.openSessions)")
            NotificationCenter.default.post(name: FloatingWindow.didFailToActiveVcSceneNotification, object: self)
        } else if let topMost = VCScene.topMostScene, topMost != self.windowScene {
            if !isDisconnected && topMost.activationState == .background {
                // 同样是background && connected，不进行转移
                logger.info("topMost is background, transfer vc window canceled. \(topMost)")
                return
            } else if topMost.activationState == .unattached {
                logger.error("topMost is unattached")
                NotificationCenter.default.post(name: FloatingWindow.didFailToActiveVcSceneNotification, object: self)
                return
            }
            if !isDisconnected && !changeSceneEnabled {
                // 目前pip活跃时，不转移
                logger.info("changeWindowScene disabled")
                return
            }
            logger.info("transfer vc window to topMost \(topMost)")
            VCScene.changeWindowScene(to: topMost)
        } else {
            logger.error("changeWindowScene failed, can't find topMostScene")
        }
    }
}

extension FloatingWindow {
    /// 兼容老代码，不建议使用
    static var current: FloatingWindow? {
        MeetingManager.shared.currentSession?.service?.router.window
    }
}
