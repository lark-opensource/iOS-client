//
//  AppStateMonitor.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/12/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import UIKit

public protocol AppInfoObserver {
    func didChangedApplicationState(_ state: UIApplication.State)
}

/// Application Context相关的工具类
public final class AppInfo {
    public static let shared = AppInfo()
    private let observers: Listeners<AppInfoObserver> = Listeners()

    /// 当前Application的状态，可在非主线程使用
    /// - note: 非主线程下，inactive值不准确
    public var applicationState: UIApplication.State {
        if Thread.isMainThread {
            return UIApplication.shared.applicationState
        } else {
            return _applicationState
        }
    }

    /// 当前屏幕方向，可在非主线程使用
    /// - note: 非主线程下，iunknown值不准确
    public var statusBarOrientation: UIInterfaceOrientation {
        if Thread.isMainThread {
            return compatibleStatusBarOrientation
        } else {
            return _statusBarOrientation
        }
    }

    @RwAtomic
    private var _applicationState: UIApplication.State = .inactive
    @RwAtomic
    private var _statusBarOrientation: UIInterfaceOrientation = .unknown

    @RwAtomic private var _otherStateDidSetup = false

    /// VC模块的创建时间
    public let createTime = CACurrentMediaTime()

    private init() {
        if Thread.isMainThread {
            self.setupApplicationState()
        } else {
            DispatchQueue.main.async {
                self.setupApplicationState()
            }
        }
    }

    deinit {
        Logger.monitor.info("UIApplication terminated")
    }

    /// 设置非 applicationState 的其他状态初始化及监听事件
    public func setup() {
        if Thread.isMainThread {
            self.setupOtherState()
        } else {
            DispatchQueue.main.async {
                self.setupOtherState()
            }
        }
    }

    private func setupApplicationState() {
        self._applicationState = UIApplication.shared.applicationState
        Logger.monitor.info("setup: UIApplication.applicationState = \(self.applicationState.logDescription)")
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive),
                                               name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    private func setupOtherState() {
        guard _otherStateDidSetup == false else { return }
        _otherStateDidSetup = true
        self._statusBarOrientation = self.compatibleStatusBarOrientation
        Logger.monitor.info("setup: UIApplication.statusBarOrientation = \(self.statusBarOrientation.logDescription)")
        Logger.monitor.info("setup: UIScreen.screens = \(UIScreen.screens)")
        NotificationCenter.default.addObserver(self, selector: #selector(willTerminate),
                                               name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didOrientationChange), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screenDidConnect(_:)), name: UIScreen.didConnectNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screenDidDisconnect(_:)), name: UIScreen.didDisconnectNotification, object: nil)
        if #available(iOS 13, *) {
            Logger.monitor.info("setup: UIWindowScene.connectScenes = \(UIApplication.shared.connectedScenes)")
            NotificationCenter.default.addObserver(self, selector: #selector(sceneWillConnect(_:)), name: UIScene.willConnectNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(sceneDidDisconnect(_:)), name: UIScene.didDisconnectNotification, object: nil)
        }
    }

    @objc private func willResignActive() {
        Logger.monitor.info("UIApplication willResignActive")
        self._applicationState = .inactive
        observers.forEach { $0.didChangedApplicationState(.inactive) }
    }

    @objc private func didEnterBackground() {
        Logger.monitor.info("UIApplication didEnterBackground")
        self._applicationState = .background
        observers.forEach { $0.didChangedApplicationState(.background) }
    }

    @objc private func willEnterForeground() {
        Logger.monitor.info("UIApplication willEnterForeground")
        self._applicationState = .inactive
        observers.forEach { $0.didChangedApplicationState(.inactive) }
    }

    @objc private func didBecomeActive() {
        Logger.monitor.info("UIApplication didBecomeActive")
        self._applicationState = .active
        observers.forEach { $0.didChangedApplicationState(.active) }
    }

    @objc private func willTerminate() {
        Logger.monitor.info("UIApplication willTerminate")
    }

    @objc private func didOrientationChange() {
        if Thread.isMainThread {
            updateStatusBarOrientation()
        } else {
            DispatchQueue.main.async {
                self.updateStatusBarOrientation()
            }
        }
    }

    @objc private func screenDidConnect(_ notification: Notification) {
        Logger.monitor.info("UIScreen screenDidConnect: \(notification), current screens = \(UIScreen.screens)")
    }

    @objc private func screenDidDisconnect(_ notification: Notification) {
        Logger.monitor.info("UIScreen screenDidDisconnect: \(notification), current screens = \(UIScreen.screens)")
    }

    private func updateStatusBarOrientation() {
        self._statusBarOrientation = self.compatibleStatusBarOrientation
        Logger.monitor.info("UIApplication didChangeStatusBarOrientation to \(self.statusBarOrientation.logDescription)")
    }

    private var compatibleStatusBarOrientation: UIInterfaceOrientation {
        if #available(iOS 13.0, *), let ws = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene {
            return ws.interfaceOrientation
        } else {
            return UIApplication.shared.statusBarOrientation
        }
    }
}

@available(iOS 13, *)
extension AppInfo {
    @objc private func sceneWillConnect(_ notification: Notification) {
        Logger.monitor.info("UIWindowScene sceneWillConnect: \(notification)")
    }

    @objc private func sceneDidDisconnect(_ notification: Notification) {
        Logger.monitor.info("UIWindowScene sceneDidDisconnect: \(notification)")
    }
}

extension UIApplication.State {
    var logDescription: String {
        switch self {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .background:
            return "background"
        default:
            return "unknown(\(rawValue))"
        }
    }
}

extension UIInterfaceOrientation {
    var logDescription: String {
        switch self {
        case .portrait:
            return "portrait"
        case .portraitUpsideDown:
            return "portraitUpsideDown"
        case .landscapeLeft:
            return "landscapeLeft"
        case .landscapeRight:
            return "landscapeRight"
        default:
            return "unknown(\(rawValue))"
        }
    }
}

extension AppInfo {
    public func addObserver(_ ob: AppInfoObserver) {
        observers.addListener(ob)
    }

    public func removeObserver(_ ob: AppInfoObserver) {
        observers.removeListener(ob)
    }
}
