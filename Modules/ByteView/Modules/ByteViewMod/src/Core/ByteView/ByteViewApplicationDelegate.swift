//
//  ByteViewApplicationDelegate.swift
//  Lark
//
//  Created by huangshun on 2019/2/14.
//  Copyright © 2019年 Bytedance.Inc. All rights reserved.
//

import Foundation
import AppContainer
import ByteViewCommon
import ByteViewWidgetService
import UniverseDesignToast

private func hostAPPStateCallback(_ port: CFMessagePort?, _ messageID: Int32, _ data: CFData?, _ info: UnsafeMutableRawPointer?) -> Unmanaged<CFData>? {
    var appState = UIApplication.shared.applicationState.rawValue
    let data = withUnsafeBytes(of: &appState) { bytes in
        Data(bytes: bytes.baseAddress!, count: bytes.count) as CFData
    }
    return Unmanaged<CFData>.passRetained(data)
}

private var setupAppStatePortOnce: Void = {
    if let group = Bundle.main.infoDictionary?["EXTENSION_GROUP"] as? String,
       let localPort = CFMessagePortCreateLocal(kCFAllocatorDefault,
                                                (group + ".host_app_state") as CFString,
                                                hostAPPStateCallback,
                                                nil,
                                                nil) {
        let source = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, localPort, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(),
                           source,
                           CFRunLoopMode.commonModes)
    }
}()

final class ByteViewApplicationDelegate: ApplicationDelegate {
    static let config = Config(name: "ByteRtc", daemon: true)

    // PIP Notification
    private static let didChangePiPStatusNotification = Foundation.Notification.Name(rawValue: "vc.pip.didChangePiPStatus")
    private static let pipStatusKey = "PIPManager.pipStatusKey"
    private var isPiPActive: Bool = false

    fileprivate static let logger = Logger.getLogger("AppDelegate").withTag("[ByteViewApplicationDelegate]")

    init(context: AppContext) {
        context.dispatcher.add(observer: self) { [weak self] (_, message) in
            self?.handleContinueUserActivity(message)
        }

        if #available(iOS 13.0, *) {
            context.dispatcher.add(observer: self) { [weak self] (_, message) in
                self?.handleSceneContinueUserActivity(message)
            }
        }

        context.dispatcher.add(observer: self) { [weak self] (_, message) in
            self?.didReceiveNotificationFront(message) ?? .just([])
        }

        context.dispatcher.add(observer: self) { [weak self] (_, message) in
            self?.didReceiveNotification(message) ?? .just(Void())
        }

        context.dispatcher.add(observer: self) { [weak self] (_, message) in
            self?.willTerminate(message)
        }

        #if canImport(CryptoKit)
        if #available(iOS 13.0, *), context.config.respondsToSceneSelectors {
            context.dispatcher.add(observer: self) { [weak self] (_, message) in
                self?.handleTraitCollectionChanged(message)
            }
        } else {
            RunLoop.main.perform {
                _ = OldWindowUpdateObserver.shared
            }
        }
        #endif

        NotificationCenter.default.addObserver(self, selector: #selector(pipStatusDidChange(_:)),
                                               name: Self.didChangePiPStatusNotification, object: nil)

        _ = setupAppStatePortOnce
    }

    func didCreate() {
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .seconds(1)) {
            ByteViewWidgetService.forceEndAllActivities("AppCreate")
        }
    }

    private func didReceiveNotification(_ message: DidReceiveNotification) -> DidReceiveNotification.HandleReturnType {
        let notification = message.notification
        if let userInfo = notification.userInfo as? [String: Any] {
            if notification.isRemote {
                NotificationCenter.default.post(name: VCNotification.didReceiveRemoteNotification, object: self,
                                                userInfo: [VCNotification.userInfoKey: userInfo])
                Self.logger.info("didReceiveRemoteNotification by DidReceiveNotification")
                return .just(Void())
            }
        }
        Self.logger.info("didReceiveNotification, isRemote = \(notification.isRemote)")
        return .just(Void())
    }

    private func didReceiveNotificationFront(_ message: DidReceiveNotificationFront) -> DidReceiveNotificationFront.HandleReturnType {
        let notification = message.notification
        if notification.isRemote, let dict = notification.userInfo as? [String: Any] {
            Self.logger.info("didReceiveRemoteNotification by DidReceiveNotificationFront")
            NotificationCenter.default.post(name: VCNotification.didReceiveRemoteNotification, object: self,
                                            userInfo: [VCNotification.userInfoKey: dict])
        } else {
            Self.logger.info("didReceiveNotificationFront, isRemote = \(notification.isRemote)")
        }
        // PIP开启时，即使在后台、通知也会被系统认为是前台通知（Front），此时需要传入PresentationOptions，否则通知不会弹出
        if #available(iOS 14.0, *), UIApplication.shared.applicationState == .background, isPiPActive {
            return .just([.sound, .banner, .list])
        }
        return .just([])
    }

    private func willTerminate(_ message: WillTerminate) -> WillTerminate.HandleReturnType {
        Self.logger.info("willTerminate")
        ByteViewWidgetService.forceEndAllActivities("Terminate")
    }

    private func handleContinueUserActivity(_ message: ContinueUserActivity) {
        Self.logger.info("handleContinueUserActivity: \(message.userActivity.activityType)")
        NotificationCenter.default.post(name: VCNotification.didReceiveContinueUserActivityNotification, object: self,
                                        userInfo: [VCNotification.userActivityKey: message.userActivity])
    }

    @available(iOS 13.0, *)
    private func handleSceneContinueUserActivity(_ message: SceneContinueUserActivity) {
        Self.logger.info("handleSceneContinueUserActivity: \(message.userActivity.activityType)")
        NotificationCenter.default.post(name: VCNotification.didReceiveContinueUserActivityNotification, object: self,
                                        userInfo: [VCNotification.userActivityKey: message.userActivity])
    }

    @available(iOS 13.0, *)
    private func handleTraitCollectionChanged(_ message: WindowSceneDidUpdateTraitCollection) {
        let scene = message.windowScene
        Self.logger.info("didUpdateWindowSceneNotification，windowScene = \(scene)")
        let previousContext = WindowSceneLayoutContext(interfaceOrientation: message.previousInterfaceOrientation, traitCollection: message.previousTraitCollection, coordinateSpace: message.previousCoordinateSpace)
        let context = WindowSceneLayoutContext(interfaceOrientation: scene.interfaceOrientation, traitCollection: scene.traitCollection, coordinateSpace: scene.coordinateSpace)
        NotificationCenter.default.post(name: VCNotification.didUpdateWindowSceneNotification, object: scene, userInfo: [
            VCNotification.previousLayoutContextKey: previousContext,
            VCNotification.layoutContextKey: context
        ])
    }

    @objc private func pipStatusDidChange(_ notification: Foundation.Notification) {
        self.isPiPActive = notification.userInfo?[Self.pipStatusKey] as? Bool ?? false
    }
}

private final class OldWindowUpdateObserver {
    static let shared = OldWindowUpdateObserver()

    private var lastFrame: CGRect?
    private var lastBounds: CGRect?
    private var coordinateSpace: UICoordinateSpace?
    private var traitCollection: UITraitCollection?
    private var interfaceOrientation: UIInterfaceOrientation?
    private var frameObservation: Any?
    private weak var window: UIWindow?
    private init() {
        self.interfaceOrientation = UIApplication.shared.statusBarOrientation
        NotificationCenter.default.addObserver(self, selector: #selector(OldWindowUpdateObserver.check), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        setupRootWindow()
    }

    private func setupRootWindow() {
        if let ow = UIApplication.shared.delegate?.window, let w = ow {
            self.coordinateSpace = w
            self.traitCollection = w.traitCollection
            self.lastFrame = w.frame
            self.lastBounds = w.bounds
            self.window = w
            self.frameObservation = w.observe(\UIWindow.frame, options: [.old, .new]) { [weak self] _, _ in
                self?.check()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.setupRootWindow()
            }
        }
    }

    @objc private func check() {
        guard let ow = UIApplication.shared.delegate?.window, let w = ow else { return }
        let coordinateSpace = w.coordinateSpace
        let traitCollection = w.traitCollection
        let interfaceOrientation = UIApplication.shared.statusBarOrientation
        guard self.coordinateSpace?.bounds != coordinateSpace.bounds
                || self.lastBounds != w.bounds
                || self.lastFrame != w.frame
                || self.traitCollection != traitCollection
                || self.interfaceOrientation != interfaceOrientation else {
            return
        }
        let previousCoordinateSpace = self.coordinateSpace
        let previousTraitCollection = self.traitCollection
        let previousInterfaceOrientation = self.interfaceOrientation
        self.coordinateSpace = coordinateSpace
        self.lastFrame = w.frame
        self.lastBounds = w.bounds
        self.traitCollection = traitCollection
        self.interfaceOrientation = interfaceOrientation
        let context = WindowSceneLayoutContext(interfaceOrientation: interfaceOrientation, traitCollection: traitCollection, coordinateSpace: coordinateSpace)
        var userInfo: [String: Any] = [VCNotification.layoutContextKey: context]
        if let previousCoordinateSpace, let previousInterfaceOrientation, let previousTraitCollection {
            userInfo[VCNotification.previousLayoutContextKey] = WindowSceneLayoutContext(interfaceOrientation: previousInterfaceOrientation, traitCollection: previousTraitCollection, coordinateSpace: previousCoordinateSpace)
        }
        ByteViewApplicationDelegate.logger.info("didUpdateWindowSceneNotification，window = \(w)")
        NotificationCenter.default.post(name: VCNotification.didUpdateWindowSceneNotification, object: w, userInfo: userInfo)
    }
}
